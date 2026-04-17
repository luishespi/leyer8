# Leyer8

App de control parental a nivel red para el hogar. Gestiona reglas de bloqueo
DNS vía NextDNS desde el móvil, sin instalar nada en los dispositivos de los hijos.

## Estructura del Monorepo

```
leyer8/
├── app/        → Proyecto Flutter (Android + iOS)
├── backend/    → Servicio Node.js + TypeScript (desplegado en Railway)
└── docs/       → Contratos de API, diagramas, decisiones técnicas
```

## Requisitos

- Flutter SDK (canal stable)
- Xcode + simulador iOS (macOS)
- Android Studio + emulador Android
- Node.js 20+ y npm
- Cuenta Firebase (Auth + Firestore)
- Cuenta NextDNS con API key

## Cómo correr la app

```bash
cd app
flutter pub get
flutter run
```

## Cómo correr el backend

```bash
cd backend
cp .env.example .env   # completa las variables
npm install
npm run dev
```

El backend queda escuchando en `http://localhost:3000`.

## Convenciones

- Ramas: `main` (producción), `develop` (integración), `feature/*` (trabajo).
- Commits: formato convencional (`feat:`, `fix:`, `chore:`, etc.).
- Un solo tag de versión cubre app + backend (`v0.1.0`).

## Estado Actual

Fase 1 en desarrollo. Ver `docs/PLAN_FASE_1.md` para alcance y cronograma.