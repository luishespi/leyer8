import 'dotenv/config';
import { z } from 'zod';

/**
 * Schema de validación de variables de entorno.
 *
 * Si falta una variable crítica o tiene un formato inválido, la app falla
 * al arrancar con un mensaje claro — mejor eso que un runtime error opaco
 * tres pantallas adentro.
 *
 * FASE B: NEXTDNS_API_KEY y FIREBASE_SERVICE_ACCOUNT ahora son requeridas.
 * Sin ellas el backend no puede verificar tokens ni crear perfiles.
 */
const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'production', 'test'])
    .default('development'),

  PORT: z.coerce.number().int().positive().default(3000),

  // NextDNS — token de la master account.
  NEXTDNS_API_KEY: z.string().min(1, 'NEXTDNS_API_KEY es requerida'),

  // Firebase — JSON de la Service Account en una sola línea.
  FIREBASE_SERVICE_ACCOUNT: z.string().min(1, 'FIREBASE_SERVICE_ACCOUNT es requerida'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Variables de entorno inválidas:');
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const config = parsed.data;

export const isDev = config.NODE_ENV === 'development';
export const isProd = config.NODE_ENV === 'production';