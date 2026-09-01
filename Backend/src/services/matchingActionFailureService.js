const { getModels } = require('../models');
const safeCodes = new Set([
  'SELF_ACTION_NOT_ALLOWED', 'PROFILE_NOT_DISCOVERABLE', 'RELATIONSHIP_BLOCKED',
  'SELF_ROSE_NOT_ALLOWED', 'RECIPIENT_NOT_AVAILABLE', 'ROSE_NOT_ALLOWED',
  'CONVERSATION_NOT_ALLOWED', 'IDEMPOTENCY_CONFLICT',
]);

async function recordFailure({ actionType, actorUserId, targetUserId, code, stage, retryable = false }) {
  if (!['like', 'super_like', 'rose'].includes(actionType) || !safeCodes.has(code)) return null;
  const target = Number(targetUserId);
  const existingTarget = Number.isInteger(target) && target > 0 ? await getModels().User.findByPk(target, { attributes: ['id'] }) : null;
  return getModels().MatchingActionFailure.create({
    actionType,
    actorUserId: Number(actorUserId) || null,
    targetUserId: existingTarget?.id || null,
    requestedTargetReference: Number.isInteger(target) && target > 0 ? String(target) : null,
    safeCode: code,
    safeCategory: 'business_rejection',
    safeStage: stage,
    retryable,
    resolutionStatus: 'not_applicable',
  });
}

module.exports = { recordFailure };
