# Leyer8 — Contratos de API (Fase 1)

**Base URL:** `https://leyer8-production.up.railway.app`

---

## Autenticación

Todos los endpoints bajo `/api/v1/*` requieren un ID Token de Firebase en el header:

```
Authorization: Bearer <idToken>
```

El token se obtiene desde el cliente Flutter con `user.getIdToken()`.
El backend verifica el token con Firebase Admin SDK y además exige que el correo esté verificado (`email_verified: true`). Si no lo está, responde `403`.

---

## Endpoints

### GET /health

Liveness probe. Sin autenticación.

**Response 200:**
```json
{
  "status": "ok",
  "service": "leyer8-backend",
  "timestamp": "2026-04-21T22:58:30.250Z"
}
```

---

### POST /api/v1/profiles/provision

Crea un perfil NextDNS para el usuario autenticado. Idempotente: si ya existe, devuelve los datos existentes.

**Headers:**
- `Authorization: Bearer <idToken>`
- `Content-Type: application/json`

**Body:** `{}` (vacío pero requerido por Fastify)

**Response 201 — Perfil creado:**
```json
{
  "status": "provisioned",
  "profileId": "abc123",
  "dnsIpv4": ["45.90.28.90", "45.90.30.90"],
  "dnsIpv6": ["2a07:a8c0::ab:c123", "2a07:a8c1::ab:c123"],
  "dohUrl": "https://dns.nextdns.io/abc123"
}
```

**Response 200 — Perfil ya existía:**
```json
{
  "status": "already_provisioned",
  "profileId": "abc123",
  "dnsIpv4": ["45.90.28.90", "45.90.30.90"],
  "dnsIpv6": ["2a07:a8c0::ab:c123", "2a07:a8c1::ab:c123"],
  "dohUrl": "https://dns.nextdns.io/abc123"
}
```

**Response 401 — Sin token o token inválido:**
```json
{
  "error": "unauthorized",
  "message": "Se requiere un token de autenticación."
}
```

**Response 403 — Correo no verificado:**
```json
{
  "error": "email_not_verified",
  "message": "Debes verificar tu correo antes de continuar."
}
```

**Response 502 — NextDNS falló (reintentos agotados):**
```json
{
  "error": "nextdns_error",
  "message": "NextDNS respondió con error: ...",
  "retryable": true
}
```

---

### GET /api/v1/profiles/me

Devuelve el perfil NextDNS del usuario autenticado.

**Headers:**
- `Authorization: Bearer <idToken>`

**Response 200:**
```json
{
  "profileId": "abc123",
  "name": "leyer8-TgZC5MtK",
  "dnsIpv4": ["45.90.28.90", "45.90.30.90"],
  "dnsIpv6": ["2a07:a8c0::ab:c123", "2a07:a8c1::ab:c123"],
  "dohUrl": "https://dns.nextdns.io/abc123",
  "dotHostname": "abc123.dns.nextdns.io",
  "defaultCategoriesApplied": false,
  "provisioningStatus": "completed",
  "onboardingCompleted": true
}
```

**Response 404 — Sin perfil:**
```json
{
  "error": "no_profile",
  "message": "Aún no tienes un perfil de protección configurado.",
  "provisioningStatus": "idle"
}
```

---

## Rate Limiting

30 requests por minuto por IP en todos los endpoints `/api/v1/*`.
El endpoint `/health` está exento.

---

## Modelo de Datos (Firestore)

### users/{uid}
```
{
  email: string,
  displayName: string,
  createdAt: timestamp,
  onboardingCompleted: boolean,
  nextdnsProfileId: string | null,
  provisioningStatus: "idle" | "in_progress" | "completed" | "failed",
  subscription: {
    status: "trial" | "active" | "inactive",
    trialEndsAt: timestamp | null
  }
}
```

### nextdns_profiles/{profileId}
```
{
  ownerUid: string,
  name: string,
  createdAt: timestamp,
  dnsIpv4: [string, string],
  dnsIpv6: [string, string],
  dohUrl: string,
  dotHostname: string,
  defaultCategoriesApplied: boolean
}
```

### Reglas de seguridad
- `users/{uid}`: read/write solo si `request.auth.uid == uid`
- `nextdns_profiles/{profileId}`: read solo si `ownerUid == auth.uid`, write solo desde Admin SDK