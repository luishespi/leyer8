import { initializeApp, cert, getApps, type App } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';

import { config } from '../config.js';

/**
 * Inicialización del Firebase Admin SDK.
 *
 * La Service Account se pasa como variable de entorno (JSON en una línea).
 * En Railway esto se configura directamente; local se lee desde .env.
 *
 * El patrón singleton evita múltiples inicializaciones si el módulo se
 * importa desde varios archivos.
 */

let app: App;
let auth: Auth;
let db: Firestore;

function initialize(): void {
  if (getApps().length > 0) {
    app = getApps()[0];
  } else {
    const serviceAccount = JSON.parse(config.FIREBASE_SERVICE_ACCOUNT);
    app = initializeApp({
      credential: cert(serviceAccount),
    });
  }

  auth = getAuth(app);
  db = getFirestore(app);
}

initialize();

export { auth, db };