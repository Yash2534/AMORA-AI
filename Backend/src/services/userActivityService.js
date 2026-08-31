const { getModels } = require('../models');

function requestContext(request) {
  return {
    ipAddress: request?.ip || request?.socket?.remoteAddress || null,
    userAgent: String(request?.headers?.['user-agent'] || '').slice(0, 500) || null,
  };
}

async function appendTimeline({ userId, eventType, title, description, status, relatedReference, administratorId, occurredAt, transaction }) {
  const { UserTimelineEvent } = getModels();
  return UserTimelineEvent.create({
    userId,
    eventType,
    title,
    description: description || null,
    status: status || null,
    relatedReference: relatedReference || null,
    administratorId: administratorId || null,
    occurredAt: occurredAt || new Date(),
  }, { transaction });
}

async function recordLoginEvent({ userId, result, authenticationMethod, failureCategory, request, transaction }) {
  const { UserLoginEvent } = getModels();
  const occurredAt = new Date();
  const event = await UserLoginEvent.create({
    userId,
    result,
    authenticationMethod,
    failureCategory: failureCategory || null,
    occurredAt,
    ...requestContext(request),
  }, { transaction });
  await appendTimeline({
    userId,
    eventType: result === 'successful' ? 'login_successful' : 'login_failed',
    title: result === 'successful' ? 'Signed in' : 'Sign-in failed',
    status: result,
    relatedReference: String(event.id),
    occurredAt,
    transaction,
  });
  return event;
}

module.exports = { appendTimeline, recordLoginEvent };
