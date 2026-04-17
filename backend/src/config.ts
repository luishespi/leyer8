import 'dotenv/config';
import { z } from 'zod';

/**
 * Schema de validación de variables de entorno.
 *
 * Si falta una variable crítica o tiene un formato inválido, la app falla
 * al arrancar con un mensaje claro — mejor eso que un runtime error opaco
 * tres pantallas adentro.
 *
 * Las variables de Fase B (NEXTDNS_API_KEY, FIREBASE_SERVICE_ACCOUNT) se
 * marcan como opcionales por ahora; se volverán requeridas cuando los
 * endpoints que las usan entren en producción.
 */
const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'production', 'test'])
    .default('development'),

  PORT: z.coerce.number().int().positive().default(3000),

  // Fase B — opcionales por ahora.
  NEXTDNS_API_KEY: z.string().optional(),
  FIREBASE_SERVICE_ACCOUNT: z.string().optional(),
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