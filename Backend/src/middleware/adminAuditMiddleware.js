const { contextFrom, recordAudit } = require('../services/adminAuditService');

module.exports = function adminAuditMiddleware(req, res, next) {
  const context = contextFrom(req);
  req.adminCorrelationId = context.correlationId;
  res.setHeader('x-correlation-id', context.correlationId);
  req.recordAdminAudit = (values) => recordAudit({
    request: req,
    administratorId: req.admin?.id,
    ...values,
  });
  next();
};
