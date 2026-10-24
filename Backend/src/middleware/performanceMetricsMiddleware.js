const metrics = require('../services/performanceMetrics');

module.exports = function performanceMetricsMiddleware(req, res, next) {
  const startedAt = process.hrtime.bigint();
  res.once('finish', () => {
    const elapsedMs = Number(process.hrtime.bigint() - startedAt) / 1e6;
    metrics.increment('http_requests', { method: req.method, statusClass: `${Math.floor(res.statusCode / 100)}xx` });
    metrics.observe('http_request_duration_ms', elapsedMs);
  });
  next();
};
