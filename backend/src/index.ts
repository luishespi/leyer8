import Fastify from 'fastify';
import cors from '@fastify/cors';

import { config, isDev } from './config';
import healthRoutes from './routes/health';

/**
 * Bootstrap del servidor Fastify.
 *
 * - Logger: pretty en dev, JSON estructurado en prod (Railway lo indexa mejor).
 * - CORS: abierto en dev para facilitar pruebas desde Flutter simulator.
 *   En prod se restringirá al dominio de la app si aplica.
 * - Host `0.0.0.0`: requerido para que Railway pueda rutear tráfico al
 *   contenedor. `localhost` solo escucha dentro del contenedor.
 */
const app = Fastify({
  logger: isDev
    ? {
        level: 'debug',
        transport: {
          target: 'pino-pretty',
          options: { colorize: true, translateTime: 'HH:MM:ss' },
        },
      }
    : { level: 'info' },
  trustProxy: true,
});

async function bootstrap(): Promise<void> {
  await app.register(cors, {
    origin: isDev ? true : false,
  });

  await app.register(healthRoutes);

  // Placeholder para rutas de Fase B.
  // await app.register(profileRoutes, { prefix: '/api/v1/profiles' });

  try {
    const address = await app.listen({
      port: config.PORT,
      host: '0.0.0.0',
    });
    app.log.info(`🛡  Leyer8 backend escuchando en ${address}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

// Apagado limpio — Railway envía SIGTERM al re-deploy.
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, async () => {
    app.log.info(`${signal} recibido, cerrando servidor...`);
    await app.close();
    process.exit(0);
  });
}

bootstrap();