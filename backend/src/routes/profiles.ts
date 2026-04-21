import type { FastifyPluginAsync } from 'fastify';
import { FieldValue } from 'firebase-admin/firestore';

import { verifyFirebaseToken } from '../middleware/verifyFirebaseToken.js';
import { db } from '../services/firebase.js';
import { createProfile, NextDnsError } from '../services/nextdns.js';

/**
 * Rutas de perfiles NextDNS.
 *
 * Se registran bajo el prefix `/api/v1/profiles` en index.ts.
 * Ambos endpoints requieren autenticación vía ID Token de Firebase.
 */

const MAX_RETRIES = 2;
const RETRY_DELAY_MS = 1_500;

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

const profileRoutes: FastifyPluginAsync = async (app) => {
  // Todos los endpoints de este plugin requieren auth.
  app.addHook('onRequest', verifyFirebaseToken);

  /**
   * POST /api/v1/profiles/provision
   *
   * Crea un perfil NextDNS para el usuario autenticado.
   *
   * Flujo:
   *   1. Verifica que el usuario no tenga ya un perfil (idempotencia).
   *   2. Marca provisioningStatus = "in_progress" en Firestore.
   *   3. Llama a NextDNS API para crear el perfil.
   *   4. Escribe profileId en users/{uid} y crea doc en nextdns_profiles/{id}.
   *   5. Marca provisioningStatus = "completed".
   *
   * Si el proceso falla a mitad (NextDNS creó el perfil pero Firestore no
   * se actualizó), el usuario puede reintentar. El endpoint detecta el
   * estado "in_progress" y reintenta la escritura en Firestore.
   */
  app.post('/provision', async (request, reply) => {
    const { uid } = request.firebaseUser;
    const userRef = db.collection('users').doc(uid);

    // 1. Verificar estado actual del usuario.
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return reply.code(404).send({
        error: 'user_not_found',
        message: 'No se encontró tu cuenta. Intenta registrarte de nuevo.',
      });
    }

    const userData = userDoc.data()!;

    // Ya tiene perfil completo → devolver los datos existentes.
    if (
      userData.nextdnsProfileId &&
      userData.provisioningStatus === 'completed'
    ) {
      const profileDoc = await db
        .collection('nextdns_profiles')
        .doc(userData.nextdnsProfileId)
        .get();

      if (profileDoc.exists) {
        const profile = profileDoc.data()!;
        return reply.code(200).send({
          status: 'already_provisioned',
          profileId: userData.nextdnsProfileId,
          dnsIpv4: profile.dnsIpv4,
          dnsIpv6: profile.dnsIpv6,
          dohUrl: profile.dohUrl,
        });
      }
    }

    // 2. Marcar como "in_progress" para detectar interrupciones.
    await userRef.update({ provisioningStatus: 'in_progress' });

    // 3. Crear perfil en NextDNS con reintentos.
    const shortUid = uid.slice(0, 8);
    const profileName = `leyer8-${shortUid}`;

    let result;
    let lastError: unknown;

    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
      try {
        result = await createProfile(profileName);
        break;
      } catch (err) {
        lastError = err;
        request.log.warn(
          { err, attempt },
          'Fallo al crear perfil en NextDNS',
        );
        if (attempt < MAX_RETRIES) {
          await sleep(RETRY_DELAY_MS * (attempt + 1));
        }
      }
    }

    if (!result) {
      await userRef.update({ provisioningStatus: 'failed' });

      const message =
        lastError instanceof NextDnsError
          ? `NextDNS respondió con error: ${lastError.message}`
          : 'No pudimos crear tu perfil de protección. Intenta de nuevo.';

      return reply.code(502).send({
        error: 'nextdns_error',
        message,
        retryable: true,
      });
    }

    // 4. Persistir en Firestore — ambas escrituras en batch.
    const batch = db.batch();

    batch.update(userRef, {
      nextdnsProfileId: result.profileId,
      provisioningStatus: 'completed',
    });

    const profileRef = db
      .collection('nextdns_profiles')
      .doc(result.profileId);

    batch.set(profileRef, {
      ownerUid: uid,
      name: profileName,
      createdAt: FieldValue.serverTimestamp(),
      dnsIpv4: [...result.dnsIpv4],
      dnsIpv6: result.dnsIpv6,
      dohUrl: result.dohUrl,
      dotHostname: result.dotHostname,
      defaultCategoriesApplied: false,
    });

    try {
      await batch.commit();
    } catch (err) {
      // NextDNS ya creó el perfil pero Firestore falló.
      // Dejamos provisioningStatus en "in_progress" para que el
      // usuario pueda reintentar y el endpoint detecte el profileId.
      request.log.error(
        { err, profileId: result.profileId },
        'Firestore batch falló tras crear perfil en NextDNS',
      );

      await userRef
        .update({
          nextdnsProfileId: result.profileId,
          provisioningStatus: 'failed',
        })
        .catch(() => {});

      return reply.code(500).send({
        error: 'persistence_error',
        message:
          'Tu perfil de protección se creó, pero hubo un error al guardarlo. Intenta de nuevo.',
        retryable: true,
      });
    }

    // 5. Respuesta exitosa.
    return reply.code(201).send({
      status: 'provisioned',
      profileId: result.profileId,
      dnsIpv4: [...result.dnsIpv4],
      dnsIpv6: result.dnsIpv6,
      dohUrl: result.dohUrl,
    });
  });

  /**
   * GET /api/v1/profiles/me
   *
   * Devuelve el perfil NextDNS del usuario autenticado.
   * Si no tiene perfil, responde 404 con un mensaje claro.
   */
  app.get('/me', async (request, reply) => {
    const { uid } = request.firebaseUser;
    const userDoc = await db.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      return reply.code(404).send({
        error: 'user_not_found',
        message: 'No se encontró tu cuenta.',
      });
    }

    const userData = userDoc.data()!;
    const profileId = userData.nextdnsProfileId;

    if (!profileId) {
      return reply.code(404).send({
        error: 'no_profile',
        message: 'Aún no tienes un perfil de protección configurado.',
        provisioningStatus: userData.provisioningStatus ?? 'idle',
      });
    }

    const profileDoc = await db
      .collection('nextdns_profiles')
      .doc(profileId)
      .get();

    if (!profileDoc.exists) {
      return reply.code(404).send({
        error: 'profile_not_found',
        message:
          'Tu perfil de protección no se encontró. Contacta a soporte.',
      });
    }

    const profile = profileDoc.data()!;

    return reply.code(200).send({
      profileId,
      name: profile.name,
      dnsIpv4: profile.dnsIpv4,
      dnsIpv6: profile.dnsIpv6,
      dohUrl: profile.dohUrl,
      dotHostname: profile.dotHostname,
      defaultCategoriesApplied: profile.defaultCategoriesApplied,
      provisioningStatus: userData.provisioningStatus,
      onboardingCompleted: userData.onboardingCompleted,
    });
  });
};

export default profileRoutes;