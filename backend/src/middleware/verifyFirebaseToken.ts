import type { FastifyRequest, FastifyReply } from 'fastify';
import { auth } from '../services/firebase.js';

/**
 * Middleware que verifica el ID Token de Firebase.
 *
 * Espera el header: `Authorization: Bearer <idToken>`
 *
 * Si el token es válido, agrega `request.firebaseUser` con el decoded token
 * (uid, email, email_verified, etc.). Si no, responde 401.
 *
 * Importante: este middleware también verifica que el correo esté verificado.
 * Si no lo está, responde 403 — la provisión de NextDNS solo ocurre tras
 * verificación para evitar perfiles huérfanos.
 */

// Extend Fastify's request type para incluir el usuario decodificado.
declare module 'fastify' {
  interface FastifyRequest {
    firebaseUser: {
      uid: string;
      email: string;
      emailVerified: boolean;
    };
  }
}

export async function verifyFirebaseToken(
  request: FastifyRequest,
  reply: FastifyReply,
): Promise<void> {
  const authHeader = request.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    reply.code(401).send({
      error: 'unauthorized',
      message: 'Se requiere un token de autenticación.',
    });
    return;
  }

  const idToken = authHeader.slice(7); // quita "Bearer "

  try {
    const decoded = await auth.verifyIdToken(idToken);

    if (!decoded.email) {
      reply.code(401).send({
        error: 'unauthorized',
        message: 'El token no contiene un correo asociado.',
      });
      return;
    }

    if (!decoded.email_verified) {
      reply.code(403).send({
        error: 'email_not_verified',
        message: 'Debes verificar tu correo antes de continuar.',
      });
      return;
    }

    request.firebaseUser = {
      uid: decoded.uid,
      email: decoded.email,
      emailVerified: decoded.email_verified ?? false,
    };
  } catch (err) {
    request.log.warn({ err }, 'Token de Firebase inválido');
    reply.code(401).send({
      error: 'invalid_token',
      message: 'El token de autenticación es inválido o expiró.',
    });
  }
}