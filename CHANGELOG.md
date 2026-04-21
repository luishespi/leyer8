# Changelog

## v0.1.0 — Fase 1 (Abril 2026)

### App Flutter
- Registro, login, recuperación de contraseña con Firebase Auth
- Verificación de correo obligatoria con polling automático
- Pantalla "Preparando tu escudo…" con provisión automática de perfil NextDNS
- Pantalla "Configura tu Router" con 3 pasos guiados y las IPs reales del perfil
- IPs copiables al portapapeles con un tap
- Design system "Serene Sentinel" aplicado: paleta navy/blanco, tipografía Plus Jakarta Sans + Inter, sin bordes de 1px, sombras ambientales tintadas
- Widgets base: PrimaryButton (gradiente 135°), TonalCard, TextFieldSentinel, ScreenScaffold, StepCard
- Arquitectura Riverpod con separación por feature (auth, onboarding)
- Guard de navegación reactivo (AuthGate) que reenruta automáticamente según estado

### Backend Node.js
- Fastify 5 con TypeScript (NodeNext)
- Endpoint `GET /health` — liveness probe
- Endpoint `POST /api/v1/profiles/provision` — crea perfil NextDNS con reintentos
- Endpoint `GET /api/v1/profiles/me` — consulta perfil del usuario
- Middleware `verifyFirebaseToken` — valida ID Token + correo verificado
- Rate limiting: 30 req/min por IP
- Validación de env vars con Zod
- Deploy en Railway con healthcheck automático

### Infraestructura
- Monorepo con app/ y backend/ al mismo nivel
- Firebase Auth + Firestore con reglas de seguridad por usuario
- NextDNS API: creación automática de perfiles con config de seguridad por defecto
- Railway: deploy automático desde GitHub