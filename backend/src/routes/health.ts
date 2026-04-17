import type { FastifyPluginAsync } from 'fastify';

/**
 * Endpoint de liveness probe.
 *
 * Railway y otras plataformas usan `/health` para verificar que el servicio
 * está vivo. Mantener simple: responder 200 rápido, sin depender de
 * servicios externos (DB, APIs, etc.) que podrían caerse y marcar el
 * backend como no saludable sin razón.
 */
const healthRoutes: FastifyPluginAsync = async (app) => {
  app.get('/health', async () => {
    return {
      status: 'ok',
      service: 'leyer8-backend',
      timestamp: new Date().toISOString(),
    };
  });
};

export default healthRoutes;