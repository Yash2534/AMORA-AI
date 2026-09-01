const { Op } = require('sequelize');
const { getModels } = require('../models');
const { compatibilityFor } = require('./compatibilityService');
const { pairKeyFor } = require('./conversationAccessService');
const { recordAudit } = require('./adminAuditService');

const actionPermission = Object.freeze({
  like: 'matching.likes.view',
  super_like: 'matching.superLikes.view',
  rose: 'matching.roses.view',
});
const can = (request, permission) => (request.adminPermissions || new Set()).has(permission);
const pageData = (page, pageSize, totalItems) => ({
  page, pageSize, totalItems, totalPages: Math.ceil(totalItems / pageSize),
});
const list = (value) => (Array.isArray(value) ? value : []);
const mediaUrl = (request, value) => {
  if (!value) return null;
  return /^https?:\/\//i.test(value) ? value : `${request.protocol}://${request.get('host')}${value}`;
};
const primaryPhoto = (profile) => {
  const photos = list(profile?.photos);
  return photos[Math.min(Number(profile?.primaryPhotoIndex || 0), Math.max(0, photos.length - 1))] || photos[0] || null;
};
const safeUser = (request, user) => ({
  userId: String(user.id),
  profileId: user.OnboardingProfile ? String(user.OnboardingProfile.id) : null,
  displayName: user.name || 'Unnamed user',
  profileImageUrl: mediaUrl(request, primaryPhoto(user.OnboardingProfile)),
  status: user.accountStatus,
});
const unavailableUser = (reference) => ({ userId: String(reference || 'unavailable'), profileId: null, displayName: 'Unavailable user', profileImageUrl: null, status: 'unavailable' });
const userInclude = (alias) => {
  const { User, OnboardingProfile } = getModels();
  return {
    model: User,
    as: alias,
    required: true,
    attributes: ['id', 'name', 'accountStatus'],
    include: [{ model: OnboardingProfile, required: false, attributes: ['id', 'photos', 'primaryPhotoIndex', 'interests', 'languages', 'relationshipGoals', 'valuedQualities', 'communicationStyle', 'lifestyle'] }],
  };
};

function dateWhere(query) {
  if (!query.createdFrom && !query.createdTo) return undefined;
  const value = {};
  if (query.createdFrom) value[Op.gte] = new Date(query.createdFrom);
  if (query.createdTo) value[Op.lte] = new Date(`${query.createdTo}T23:59:59.999Z`);
  return value;
}

async function linkedMatch(firstId, secondId) {
  const { Match } = getModels();
  return Match.findOne({
    where: { userOneId: Math.min(firstId, secondId), userTwoId: Math.max(firstId, secondId) },
    attributes: ['id'],
  });
}

async function discoverActionJson(request, row) {
  const match = await linkedMatch(Number(row.actorUserId), Number(row.targetUserId));
  return {
    actionId: `discover_${row.id}`,
    actionType: row.action === 'superLike' ? 'super_like' : 'like',
    sender: safeUser(request, row.actor),
    target: safeUser(request, row.target),
    status: 'processed',
    result: match ? 'matched' : 'recorded',
    createdAt: row.createdAt,
    processedAt: row.updatedAt,
    matched: Boolean(match),
    matchId: match ? String(match.id) : null,
    source: 'consumer_discover',
    failure: null,
    safeChecks: [],
  };
}

async function roseActionJson(request, row) {
  const match = await linkedMatch(Number(row.senderId), Number(row.recipientId));
  return {
    actionId: `rose_${row.id}`,
    actionType: 'rose',
    sender: safeUser(request, row.sender),
    target: safeUser(request, row.recipient),
    status: row.status,
    result: row.status,
    createdAt: row.createdAt,
    processedAt: row.updatedAt,
    matched: Boolean(match),
    matchId: match ? String(match.id) : null,
    source: row.conversationId ? 'conversation' : 'consumer_profile',
    failure: null,
    safeChecks: [],
  };
}

async function failureActionJson(request, row) {
  const { User, OnboardingProfile } = getModels();
  const ids = [row.actorUserId, row.targetUserId].filter(Boolean);
  const users = ids.length ? await User.findAll({ where: { id: ids }, attributes: ['id', 'name', 'accountStatus'], include: [{ model: OnboardingProfile, required: false, attributes: ['id', 'photos', 'primaryPhotoIndex'] }] }) : [];
  const byId = new Map(users.map((user) => [Number(user.id), user]));
  return {
    actionId: `failure_${row.id}`,
    actionType: row.actionType,
    sender: byId.has(Number(row.actorUserId)) ? safeUser(request, byId.get(Number(row.actorUserId))) : unavailableUser(row.actorUserId),
    target: byId.has(Number(row.targetUserId)) ? safeUser(request, byId.get(Number(row.targetUserId))) : unavailableUser(row.requestedTargetReference),
    status: 'failed', result: 'rejected', createdAt: row.createdAt, processedAt: row.createdAt,
    matched: false, matchId: null, source: 'consumer_action',
    failure: {
      category: row.safeCategory, safeCode: row.safeCode, safeLabel: row.safeCode.toLowerCase().replaceAll('_', ' '),
      safeStage: row.safeStage, retryable: row.retryable, resolutionStatus: row.resolutionStatus,
    },
    safeChecks: [],
  };
}

function searchWhere(query, aliases) {
  if (!query.search) return undefined;
  const pattern = `%${query.search.trim()}%`;
  return { [Op.or]: aliases.map((alias) => ({ [`$${alias}.name$`]: { [Op.like]: pattern } })) };
}

async function actions(request, query) {
  const page = Number(query.page || 1);
  const pageSize = Number(query.pageSize || 20);
  const direction = String(query.sortDirection || 'desc').toUpperCase();
  if (query.failureCode || query.status === 'failed' || query.result === 'failed' || query.result === 'rejected') {
    const where = { actionType: query.type };
    if (query.failureCode) where.safeCode = query.failureCode.toUpperCase();
    if (dateWhere(query)) where.createdAt = dateWhere(query);
    const rows = await getModels().MatchingActionFailure.findAll({ where, order: [['createdAt', direction], ['id', 'DESC']] });
    let items = await Promise.all(rows.map((row) => failureActionJson(request, row)));
    if (query.search) {
      const needle = query.search.trim().toLocaleLowerCase('en-US');
      items = items.filter((item) => item.sender.displayName.toLocaleLowerCase('en-US').includes(needle) || item.target.displayName.toLocaleLowerCase('en-US').includes(needle));
    }
    const totalItems = items.length;
    return { items: items.slice((page - 1) * pageSize, page * pageSize), pagination: pageData(page, pageSize, totalItems) };
  }
  if (query.type === 'rose') {
    const { RoseTransaction } = getModels();
    const where = {};
    if (dateWhere(query)) where.createdAt = dateWhere(query);
    if (query.status) where.status = query.status;
    if (query.result) where.status = query.result;
    if (query.failureCode) return { items: [], pagination: pageData(page, pageSize, 0) };
    if (searchWhere(query, ['sender', 'recipient'])) where[Op.and] = [searchWhere(query, ['sender', 'recipient'])];
    const result = await RoseTransaction.findAndCountAll({
      where,
      include: [userInclude('sender'), userInclude('recipient')],
      distinct: true,
      limit: pageSize,
      offset: (page - 1) * pageSize,
      order: [[query.sortBy === 'processedAt' ? 'updatedAt' : 'createdAt', direction], ['id', 'DESC']],
      subQuery: false,
    });
    return { items: await Promise.all(result.rows.map((row) => roseActionJson(request, row))), pagination: pageData(page, pageSize, result.count) };
  }
  const { DiscoverAction } = getModels();
  const action = query.type === 'super_like' ? 'superLike' : 'like';
  const where = { action };
  if (dateWhere(query)) where.createdAt = dateWhere(query);
  if (query.status && query.status !== 'processed') return { items: [], pagination: pageData(page, pageSize, 0) };
  if (query.failureCode) return { items: [], pagination: pageData(page, pageSize, 0) };
  if (searchWhere(query, ['actor', 'target'])) where[Op.and] = [searchWhere(query, ['actor', 'target'])];
  if (query.result) {
    const rows = await DiscoverAction.findAll({
      where,
      include: [userInclude('actor'), userInclude('target')],
      order: [[query.sortBy === 'processedAt' ? 'updatedAt' : 'createdAt', direction], ['id', 'DESC']],
      subQuery: false,
    });
    const filtered = (await Promise.all(rows.map((row) => discoverActionJson(request, row)))).filter((item) => item.result === query.result);
    return { items: filtered.slice((page - 1) * pageSize, page * pageSize), pagination: pageData(page, pageSize, filtered.length) };
  }
  const result = await DiscoverAction.findAndCountAll({
    where,
    include: [userInclude('actor'), userInclude('target')],
    distinct: true,
    limit: pageSize,
    offset: (page - 1) * pageSize,
    order: [[query.sortBy === 'processedAt' ? 'updatedAt' : 'createdAt', direction], ['id', 'DESC']],
    subQuery: false,
  });
  const items = await Promise.all(result.rows.map((row) => discoverActionJson(request, row)));
  return { items, pagination: pageData(page, pageSize, result.count) };
}

async function action(request, actionId) {
  const [kind, idText] = String(actionId).split('_');
  const id = Number(idText);
  if (!Number.isInteger(id) || id < 1) return null;
  if (kind === 'failure') {
    const row = await getModels().MatchingActionFailure.findByPk(id);
    if (!row) return null;
    if (!can(request, actionPermission[row.actionType]) || !can(request, 'matching.actions.failed.view')) return { permissionDenied: true };
    return failureActionJson(request, row);
  }
  if (kind === 'rose') {
    if (!can(request, actionPermission.rose)) return { permissionDenied: true };
    const row = await getModels().RoseTransaction.findByPk(id, { include: [userInclude('sender'), userInclude('recipient')] });
    return row ? roseActionJson(request, row) : null;
  }
  if (kind !== 'discover') return null;
  const row = await getModels().DiscoverAction.findByPk(id, { include: [userInclude('actor'), userInclude('target')] });
  if (!row || row.action === 'pass') return null;
  const permission = row.action === 'superLike' ? actionPermission.super_like : actionPermission.like;
  if (!can(request, permission)) return { permissionDenied: true };
  return discoverActionJson(request, row);
}

function scoreFor(match) {
  return compatibilityFor(match.userOne.OnboardingProfile, match.userTwo.OnboardingProfile);
}

async function conversationFor(match) {
  return getModels().Conversation.findOne({ where: { pairKey: pairKeyFor(match.userOneId, match.userTwoId) }, attributes: ['id', 'createdAt'] });
}

async function matchJson(request, row) {
  const conversation = await conversationFor(row);
  const compatibility = scoreFor(row);
  return {
    matchId: String(row.id),
    userA: safeUser(request, row.userOne),
    userB: safeUser(request, row.userTwo),
    source: 'mutual_like',
    status: 'active',
    aiScore: compatibility.score,
    aiScoreScale: '0-100',
    conversationId: conversation ? String(conversation.id) : null,
    conversationExists: Boolean(conversation),
    createdAt: row.matchedAt,
    updatedAt: row.matchedAt,
  };
}

async function matchRows() {
  return getModels().Match.findAll({ include: [userInclude('userOne'), userInclude('userTwo')] });
}

async function matches(request, query) {
  const page = Number(query.page || 1);
  const pageSize = Number(query.pageSize || 20);
  let rows = await matchRows();
  let values = await Promise.all(rows.map((row) => matchJson(request, row)));
  if (query.search) {
    const needle = query.search.trim().toLocaleLowerCase('en-US');
    values = values.filter((row) => row.userA.displayName.toLocaleLowerCase('en-US').includes(needle) || row.userB.displayName.toLocaleLowerCase('en-US').includes(needle));
  }
  if (query.source) values = values.filter((row) => row.source === query.source);
  if (query.status) values = values.filter((row) => row.status === query.status);
  if (query.conversationCreated != null) values = values.filter((row) => row.conversationExists === (String(query.conversationCreated) === 'true'));
  if (query.createdFrom) values = values.filter((row) => new Date(row.createdAt) >= new Date(query.createdFrom));
  if (query.createdTo) values = values.filter((row) => new Date(row.createdAt) <= new Date(`${query.createdTo}T23:59:59.999Z`));
  const direction = String(query.sortDirection || 'desc').toLowerCase() === 'asc' ? 1 : -1;
  const field = query.sortBy === 'aiScore' ? 'aiScore' : 'createdAt';
  values.sort((left, right) => direction * (field === 'aiScore' ? Number(left.aiScore) - Number(right.aiScore) : new Date(left.createdAt) - new Date(right.createdAt)) || Number(right.matchId) - Number(left.matchId));
  const totalItems = values.length;
  return { items: values.slice((page - 1) * pageSize, page * pageSize), pagination: pageData(page, pageSize, totalItems) };
}

async function findMatch(request, matchId) {
  const row = await getModels().Match.findByPk(matchId, { include: [userInclude('userOne'), userInclude('userTwo')] });
  if (!row) return null;
  const summary = await matchJson(request, row);
  const mutual = await getModels().DiscoverAction.findAll({
    where: {
      [Op.or]: [
        { actorUserId: row.userOneId, targetUserId: row.userTwoId },
        { actorUserId: row.userTwoId, targetUserId: row.userOneId },
      ],
      action: { [Op.in]: ['like', 'superLike'] },
    },
    attributes: ['id'],
    order: [['id', 'ASC']],
  });
  return { summary, mutualActionIds: mutual.map((item) => `discover_${item.id}`), requestReference: request.adminCorrelationId || null };
}

async function aiScore(request, matchId, includeExplanation) {
  const row = await getModels().Match.findByPk(matchId, { include: [userInclude('userOne'), userInclude('userTwo')] });
  if (!row) return null;
  const compatibility = scoreFor(row);
  await recordAudit({ request, administratorId: request.admin.id, action: 'admin.matching.ai_score_viewed', targetType: 'match', targetId: row.id, metadata: { explanationIncluded: Boolean(includeExplanation) } });
  return {
    scoreId: `compatibility_${row.id}_v1`,
    matchId: String(row.id),
    score: compatibility.score,
    scaleMinimum: 0,
    scaleMaximum: 100,
    displayPercentage: compatibility.score,
    compatibilityBand: compatibility.score >= 80 ? 'high' : compatibility.score >= 65 ? 'medium' : 'standard',
    confidence: 'deterministic',
    generatedAt: row.matchedAt,
    modelVersion: compatibility.method,
    explanationVersion: 'safe_admin_v1',
    factors: includeExplanation ? compatibility.reasons.map((reason) => ({ key: reason.factor, label: reason.label, contribution: 'positive', adminVisible: true })) : [],
    limitations: [compatibility.disclaimer],
    manualReviewRequired: false,
    status: 'available',
    stale: false,
  };
}

async function history(matchId) {
  const { AdminAuditLog } = getModels();
  const rows = await AdminAuditLog.findAll({
    where: { targetType: 'match', targetId: String(matchId) },
    attributes: ['id', 'action', 'createdAt'],
    include: [{ model: getModels().Administrator, as: 'administrator', required: false, attributes: ['name'] }],
    order: [['createdAt', 'DESC'], ['id', 'DESC']],
    limit: 100,
  });
  return { items: rows.map((row) => ({ id: String(row.id), action: row.action, actorName: row.administrator?.name, occurredAt: row.createdAt, safeSummary: 'Authorized Admin matching record access.' })) };
}

module.exports = { actionPermission, actions, action, matches, findMatch, aiScore, history };
