const { closeRealtimeServer } = require('../realtime/realtimeHub');
const { closeDatabase } = require('../config/db');
const readiness = require('./serviceReadiness');

function closeHttpServer(server) {
  if (!server?.listening) return Promise.resolve();
  return new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
}

function createGracefulShutdown({
  server,
  timeoutMs,
  logger = console,
  exit = () => {},
  closeHttp = closeHttpServer,
  closeRealtime = closeRealtimeServer,
  closeDb = closeDatabase,
}) {
  let shutdownPromise;
  return function shutdown(signal = 'shutdown') {
    if (shutdownPromise) return shutdownPromise;
    readiness.markShuttingDown(true);
    logger.info(`[Shutdown] ${signal} received; draining services.`);
    shutdownPromise = new Promise((resolve) => {
      const timer = setTimeout(() => {
        logger.error('[Shutdown] Grace period expired; resources may not have drained completely.');
        exit(1);
        resolve({ timedOut: true });
      }, timeoutMs);
      timer.unref?.();
      (async () => {
        try {
          await closeHttp(server);
          await closeRealtime();
          await closeDb();
          clearTimeout(timer);
          logger.info('[Shutdown] HTTP, realtime, and database resources closed.');
          exit(0);
          resolve({ timedOut: false });
        } catch (error) {
          clearTimeout(timer);
          logger.error('[Shutdown] Resource shutdown failed.', { error: { name: error.name, code: error.code } });
          exit(1);
          resolve({ timedOut: false, error });
        }
      })();
    });
    return shutdownPromise;
  };
}

module.exports = { createGracefulShutdown, closeHttpServer };
