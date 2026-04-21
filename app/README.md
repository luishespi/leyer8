# Leyer8

App de control parental a nivel red para el hogar. Gestiona reglas de bloqueo
DNS vía NextDNS desde el móvil, sin instalar nada en los dispositivos de los hijos.

## Estructura del Monorepo

```
leyer8/
├── app/           → Proyecto Flutter (Android + iOS)
├── backend/       → Servicio Node.js + TypeScript (Railway)
└── docs/          → Contratos de API, decisiones técnicas
```

## Stack

| Capa            | Tecnología                              |
|-----------------|-----------------------------------------|
| App móvil       | Flutter, Riverpod, Firebase SDK         |
| Backend         | Node.js, TypeScript, Fastify 5          |
| DNS / Filtrado  | NextDNS API                             |
| Base de datos   | Firebase Firestore                      |
| Autenticación   | Firebase Auth (email/password)          |
| Hosting backend | Railway                                 |

## URLs de Producción

- **Backend:** `https://leyer8-production.up.railway.app`
- **Health check:** `https://leyer8-production.up.railway.app/health`
- **Firebase:** proyecto `leyer8-96d1a`

## Requisitos

- Flutter SDK (canal stable, 3.11+)
- Xcode + simulador iOS (macOS)
- Android Studio + emulador Android
- Node.js 20+ y npm
- Cuenta Firebase con Auth + Firestore habilitados
- Cuenta NextDNS con API key

## Cómo correr la app

```bash
cd app
flutter pub get
flutter run
```

La app apunta al backend de producción por defecto.
Para apuntar a localhost, editar `lib/core/config/app_config.dart`.

## Cómo correr el backend

```bash
cd backend
cp .env.example .env   # completar NEXTDNS_API_KEY y FIREBASE_SERVICE_ACCOUNT
npm install
npm run dev
```

El backend queda escuchando en `http://localhost:3000`.

### Variables de entorno requeridas

| Variable                   | Descripción                                          |
|----------------------------|------------------------------------------------------|
| `NODE_ENV`                 | `development` o `production`                         |
| `PORT`                     | Puerto del servidor (default: 3000)                  |
| `NEXTDNS_API_KEY`          | API key de NextDNS (Account → API)                   |
| `FIREBASE_SERVICE_ACCOUNT` | JSON de la Service Account en una sola línea          |

## Convenciones

- Ramas: `main` (producción), `develop` (integración), `feature/*` (trabajo)
- Commits: formato convencional (`feat:`, `fix:`, `chore:`, etc.)
- Un solo tag de versión cubre app + backend (`v0.1.0`)

## Documentación

- **Contratos de API:** `docs/api-contracts.md`
- **Plan de desarrollo:** `docs/PLAN_FASE_1.md`
- **Design system:** `docs/DESIGN.md`

## Flujo del Usuario (Fase 1)

```
Registro → Verificación de correo → Provisión automática de NextDNS
→ Configuración del router (3 pasos) → Dashboard
```

## Estado Actual

Fase 1 completada. Ver `docs/PLAN_FASE_1.md` para el detalle.

## Handoff al Cliente

Para operar la app en producción con tu propia cuenta:

1. **NextDNS:** crear cuenta en nextdns.io, obtener API key, reemplazar `NEXTDNS_API_KEY` en Railway.
2. **Firebase:** transferir propiedad del proyecto `leyer8-96d1a` o crear uno nuevo y actualizar `firebase_options.dart`.
3. **Railway:** las variables de entorno ya están configuradas. Solo cambiar la API key de NextDNS.