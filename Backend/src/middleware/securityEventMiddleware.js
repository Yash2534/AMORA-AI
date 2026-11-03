const crypto = require('crypto');
const { contextFrom, recordAudit } = require('../services/adminAuditService');
const logger = require('../utils/logger');

const USER_SENSITIVE_PREFIXES = [
  '/api/account',
  '/api/privacy-requests',
  '/api/privacy/grievances',
  '/api/v1/privacy/grievances',
  '/api/media',
  '/api/identity-verification',
  '/api/reports',
  '/api/blocks',
];

const ROUTE_EVENTS = [
  ['POST', /^\/api\/auth\/login$/, 'user.auth.login', 'user'],
  ['POST', /^\/api\/auth\/logout$/, 'user.auth.logout', 'session'],
  ['POST', /^\/api\/auth\/verify-account$/, 'user.auth.otp_verification', 'user'],
  ['POST', /^\/api\/auth\/resend-verification-code$/, 'user.auth.otp_requested', 'user'],
  ['POST', /^\/api\/auth\/forgot-password$/, 'user.auth.password_reset_requested', 'user'],
  ['POST', /^\/api\/auth\/verify-reset-code$/, 'user.auth.password_reset_otp_verification', 'user'],
  ['POST', /^\/api\/auth\/reset-password$/, 'user.auth.password_reset', 'user'],
  ['POST', /^\/api\/auth\/change-password$/, 'user.auth.password_changed', 'user'],
  ['POST', /^\/api\/auth\/refresh-token$/, 'user.auth.session_refreshed', 'session'],
  ['POST', /^\/api\/auth\/reactivate$/, 'user.account.reactivated', 'user'],
  ['POST', /^\/api\/account\/deactivate$/, 'user.account.deactivated', 'user'],
  ['POST', /^\/api\/account\/phone-change\/request$/, 'user.phone.change_requested', 'user'],
  ['POST', /^\/api\/account\/phone-change\/confirm$/, 'user.phone.change_confirmed', 'user'],
  ['POST', /^\/api\/account\/delete\/send-otp$/, 'user.account.deletion_otp_requested', 'user'],
  ['POST', /^\/api\/account\/delete\/confirm$/, 'user.account.deleted', 'user'],
  ['POST', /^\/api\/privacy-requests$/, 'user.privacy.request_created', 'privacy_request'],
  ['POST', /^\/api\/privacy-requests\/\d+\/step-up\/verify$/, 'user.privacy.step_up_verified', 'privacy_request'],
  ['POST', /^\/api\/privacy-requests\/\d+\/access$/, 'user.privacy.access_completed', 'privacy_request'],
  ['POST', /^\/api\/privacy-requests\/\d+\/withdrawal$/, 'user.privacy.consent_withdrawn', 'privacy_request'],
  ['POST', /^\/api\/privacy-requests\/\d+\/export$/, 'user.privacy.export_generated', 'privacy_request'],
  ['GET', /^\/api\/privacy-requests\/\d+\/export\/download$/, 'user.privacy.export_downloaded', 'privacy_request'],
  ['POST', /^\/api\/privacy-requests\/\d+\/correction$/, 'user.privacy.correction_submitted', 'privacy_request'],
  ['POST', /^\/api\/(?:v1\/)?privacy\/grievances$/, 'user.privacy.grievance_submitted', 'privacy_grievance'],
  ['GET', /^\/api\/(?:v1\/)?privacy\/grievances\/[^/]+$/, 'user.privacy.grievance_status_viewed', 'privacy_grievance'],
  ['POST', /^\/api\/reports$/, 'user.safety.report_submitted', 'report'],
  ['POST', /^\/api\/blocks\/\d+$/, 'user.safety.user_blocked', 'user'],
  ['DELETE', /^\/api\/blocks\/\d+$/, 'user.safety.user_unblocked', 'user'],
  ['POST', /^\/api\/identity-verification\/submissions$/, 'user.identity.submitted', 'identity_verification'],
];

function bounded(value, max = 191) {
  const text = String(value == null ? '' : value).trim();
  return text ? text.slice(0, max) : null;
}

function idFromPath(pathname) {
  const values = pathname.match(/\/(\d+)(?:\/|$)/g);
  if (!values?.length) return null;
  const match = values.at(-1).match(/\d+/);
  return match ? match[0] : null;
}

function classifySecurityEvent(request, statusCode) {
  const method = String(request.method || 'GET').toUpperCase();
  const pathname = String(request.originalUrl || request.url || '').split('?')[0];
  const outcome = statusCode < 400 ? 'success' : 'failed';
  const intended = ROUTE_EVENTS.find(([verb, pattern]) => verb === method && pattern.test(pathname));

  if (statusCode === 429) {
    return {
      action: 'security.rate_limit_triggered',
      targetType: intended?.[3] || 'endpoint',
      targetId: idFromPath(pathname),
      metadata: { outcome: 'failed', severity: 'warning', intendedAction: intended?.[2] || null },
    };
  }
  if ((statusCode === 401 || statusCode === 403) && pathname.startsWith('/api/admin/')) {
    return {
      action: 'security.admin_access_denied',
      targetType: 'endpoint',
      targetId: null,
      metadata: { outcome: 'failed', severity: 'warning' },
    };
  }
  if ((statusCode === 401 || statusCode === 403)
    && USER_SENSITIVE_PREFIXES.some((prefix) => pathname.startsWith(prefix))) {
    return {
      action: 'security.sensitive_access_denied',
      targetType: intended?.[3] || 'endpoint',
      targetId: idFromPath(pathname),
      metadata: { outcome: 'failed', severity: 'warning', intendedAction: intended?.[2] || null },
    };
  }
  if (pathname.startsWith('/api/admin/v1/') && statusCode < 400) {
    const sensitiveRead = method === 'GET' && /\/(?:media|verifications|chat\/messages|audit-logs)(?:\/|$)/.test(pathname);
    const mutation = ['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)
      && !pathname.startsWith('/api/admin/v1/auth/');
    if (sensitiveRead || mutation) {
      return {
        action: sensitiveRead ? 'admin.sensitive_data_accessed' : 'admin.sensitive_action_completed',
        targetType: 'admin_endpoint',
        targetId: idFromPath(pathname),
        metadata: { outcome: 'success', severity: sensitiveRead ? 'info' : 'notice' },
      };
    }
  }
  if (!intended) return null;
  return {
    action: intended[2],
    targetType: intended[3],
    targetId: idFromPath(pathname),
    metadata: { outcome, severity: outcome === 'failed' ? 'warning' : 'info' },
  };
}

function deviceReference(request) {
  const value = bounded(request.headers?.['x-device-id'], 500);
  return value ? crypto.createHash('sha256').update(value).digest('hex').slice(0, 24) : null;
}

module.exports = function securityEventMiddleware(request, response, next) {
  const context = contextFrom(request);
  request.adminCorrelationId ||= context.correlationId;
  if (!response.headersSent) response.setHeader('x-correlation-id', request.adminCorrelationId);

  response.once('finish', () => {
    const event = classifySecurityEvent(request, response.statusCode);
    if (!event) return;
    const actorUserId = Number(request.user?.sub || request.authUser?.id || 0) || null;
    recordAudit({
      request,
      administratorId: request.admin?.id || null,
      action: event.action,
      targetType: event.targetType,
      targetId: event.targetId,
      metadata: {
        ...event.metadata,
        actorType: request.admin ? 'administrator' : actorUserId ? 'user' : 'anonymous',
        actorUserId,
        statusCode: response.statusCode,
        deviceReference: deviceReference(request),
      },
    }).catch((error) => logger.error('Security event persistence failed.', {
      action: event.action,
      errorCode: error.code || error.name,
      correlationId: request.adminCorrelationId,
    }));
  });
  next();
};

module.exports._test = { classifySecurityEvent, deviceReference, ROUTE_EVENTS };
