const { Op } = require('sequelize');
const { getModels } = require('../models');
const { recordAudit } = require('./adminAuditService');

const can = (request, permission) => (request.adminPermissions || new Set()).has(permission);

function maskEmail(value) {
  const [local, domain] = String(value || '').split('@');
  if (!local || !domain) return null;
  return `${local.slice(0, 1)}***@${domain}`;
}

function maskedUserSummary(user) {
  if (!user) return null;
  const email = maskEmail(user.email);
  return [String(user.name || '').trim(), email].filter(Boolean).join(' • ') || null;
}

function providerLabel(value) {
  const provider = String(value || '').trim();
  return provider ? provider.charAt(0).toUpperCase() + provider.slice(1) : null;
}

function planFeatures(value) {
  if (!Array.isArray(value)) return [];
  return value.slice(0, 100).map((item) => {
    if (typeof item === 'string' && item.trim()) {
      return { key: item.trim().slice(0, 100), label: item.trim().slice(0, 240), enabled: true };
    }
    if (!item || typeof item !== 'object') return null;
    const key = String(item.key || item.id || item.name || '').trim().slice(0, 100);
    const label = String(item.label || item.name || key).trim().slice(0, 240);
    return key && label ? { key, label, enabled: item.enabled !== false } : null;
  }).filter(Boolean);
}

function planLimits(value) {
  if (!value || Array.isArray(value) || typeof value !== 'object') return [];
  return Object.entries(value).slice(0, 100).map(([key, raw]) => {
    const numeric = Number(raw);
    if (!Number.isSafeInteger(numeric)) return null;
    return { key: String(key).slice(0, 100), label: String(key).slice(0, 240), value: numeric };
  }).filter(Boolean);
}

function planJson(plan, activeMemberships = null) {
  return {
    planId: String(plan.id),
    name: plan.displayName || plan.name,
    code: String(plan.id),
    status: plan.active ? 'active' : 'inactive',
    price: {
      amountMinor: Number(plan.priceMinor),
      currency: plan.currency,
      minorUnitDigits: 2,
    },
    allowedActions: [],
    description: plan.description,
    durationCount: Number(plan.billingInterval),
    durationUnit: plan.billingPeriod,
    activeMemberships,
    updatedAt: plan.updatedAt,
    features: planFeatures(plan.features),
    limits: planLimits(plan.entitlements),
  };
}

async function membershipCounts(planIds) {
  if (!planIds.length) return new Map();
  const { Subscription } = getModels();
  const rows = await Subscription.findAll({
    attributes: ['planId', [Subscription.sequelize.fn('COUNT', Subscription.sequelize.col('id')), 'count']],
    where: { planId: { [Op.in]: planIds }, status: { [Op.in]: ['active', 'trialing'] } },
    group: ['planId'],
    raw: true,
  });
  return new Map(rows.map((row) => [String(row.planId), Number(row.count)]));
}

async function plans(request, page) {
  const { SubscriptionPlan } = getModels();
  const where = {};
  if (request.query.search) {
    const search = String(request.query.search).trim();
    where[Op.or] = [
      { id: { [Op.like]: `%${search}%` } },
      { name: { [Op.like]: `%${search}%` } },
      { displayName: { [Op.like]: `%${search}%` } },
    ];
  }
  if (request.query.status) where.active = request.query.status === 'active';
  if (request.query.currency) where.currency = String(request.query.currency).toUpperCase();
  const sortMap = { updatedAt: 'updatedAt', createdAt: 'createdAt', name: 'displayName', priceMinor: 'priceMinor', status: 'active' };
  const sortField = sortMap[request.query.sortBy] || 'updatedAt';
  const direction = String(request.query.sortDirection || 'desc').toUpperCase();
  const result = await SubscriptionPlan.findAndCountAll({
    where,
    limit: page.pageSize,
    offset: page.offset,
    order: [[sortField, direction], ['id', 'ASC']],
  });
  const counts = await membershipCounts(result.rows.map((plan) => String(plan.id)));
  return {
    items: result.rows.map((plan) => planJson(plan, counts.get(String(plan.id)) || 0)),
    pagination: {
      page: page.page,
      pageSize: page.pageSize,
      totalItems: result.count,
      totalPages: Math.ceil(result.count / page.pageSize),
    },
  };
}

async function plan(request, planId) {
  const { SubscriptionPlan, Subscription } = getModels();
  const row = await SubscriptionPlan.findByPk(planId);
  if (!row) return null;
  const activeMemberships = await Subscription.count({
    where: { planId, status: { [Op.in]: ['active', 'trialing'] } },
  });
  return planJson(row, activeMemberships);
}

function transactionWhere(request) {
  const where = {};
  if (request.query.status) where.status = request.query.status;
  if (request.query.currency) where.currency = String(request.query.currency).toUpperCase();
  if (request.query.planId) where.planId = request.query.planId;
  if (request.query.hasRefund === true) {
    where[Op.and] = [...(where[Op.and] || []), { status: 'refunded' }];
  }
  if (request.query.hasRefund === false) {
    where[Op.and] = [...(where[Op.and] || []), { status: { [Op.ne]: 'refunded' } }];
  }
  if (request.query.from || request.query.to) {
    where.createdAt = {};
    if (request.query.from) where.createdAt[Op.gte] = new Date(request.query.from);
    if (request.query.to) where.createdAt[Op.lte] = new Date(request.query.to);
  }
  if (request.query.providerReference) {
    const reference = String(request.query.providerReference).trim();
    where[Op.and] = [{ [Op.or]: [
      { providerOrderId: reference },
      { providerPaymentId: reference },
    ] }];
  }
  if (request.query.search) {
    const search = String(request.query.search).trim();
    const terms = [
      { planId: { [Op.like]: `%${search}%` } },
      { '$user.name$': { [Op.like]: `%${search}%` } },
      { '$plan.displayName$': { [Op.like]: `%${search}%` } },
    ];
    if (/^\d+$/.test(search)) terms.push({ id: search }, { userId: search });
    where[Op.and] = [...(where[Op.and] || []), { [Op.or]: terms }];
  }
  return where;
}

function reconciliationEventJson(event, includeSensitive) {
  return {
    eventId: String(event.id),
    eventType: event.eventType,
    status: event.status,
    receivedAt: event.createdAt,
    processedAt: event.processedAt,
    ...(includeSensitive ? { providerEventId: event.providerEventId } : {}),
    ...(event.status === 'failed' ? { errorCategory: 'provider_event_processing_failed' } : {}),
  };
}

function transactionJson(request, payment, options = {}) {
  const includeSensitive = options.includeSensitive === true;
  const includeReconciliation = options.includeReconciliation === true;
  const events = Array.isArray(payment.events) ? payment.events : [];
  const latestEvent = events[0] || null;
  const subscription = options.subscription;
  const membershipId = subscription && String(subscription.planId) === String(payment.planId)
    ? String(subscription.id) : null;
  return {
    transactionId: String(payment.id),
    status: payment.status,
    amount: {
      amountMinor: Number(payment.amountMinor),
      currency: payment.currency,
      minorUnitDigits: 2,
    },
    allowedActions: [
      ...(can(request, 'payments.audit.view') ? ['audit'] : []),
    ],
    refundEligibility: {
      eligible: false,
      fullRefundAllowed: false,
      partialRefundAllowed: false,
      allowedActions: [],
      ineligibilityCode: 'REFUND_OPERATION_NOT_AVAILABLE',
      message: 'Refund orchestration requires an approved provider and reconciliation policy.',
    },
    membershipId,
    userId: String(payment.userId),
    maskedUserSummary: maskedUserSummary(payment.user),
    planId: payment.planId == null ? null : String(payment.planId),
    planName: payment.plan?.displayName || payment.plan?.name || null,
    providerLabel: providerLabel(payment.provider),
    refundStatus: payment.status === 'refunded' ? 'refunded' : null,
    safeFailureCategory: payment.status === 'failed' ? (payment.failureCode || 'payment_failed') : null,
    reconciliationStatus: latestEvent?.status || 'not_recorded',
    webhookStatus: latestEvent?.status || 'not_recorded',
    paidAt: payment.verifiedAt,
    createdAt: payment.createdAt,
    updatedAt: payment.updatedAt,
    ...(includeSensitive ? {
      providerTransactionId: payment.providerPaymentId || payment.providerOrderId || null,
      providerOrderId: payment.providerOrderId,
      providerPaymentId: payment.providerPaymentId,
    } : {}),
    ...(includeReconciliation ? {
      reconciliationHistory: events.map((event) => reconciliationEventJson(event, includeSensitive)),
    } : {}),
  };
}

async function subscriptionsFor(payments) {
  const ids = [...new Set(payments.map((payment) => Number(payment.userId)))];
  if (!ids.length) return new Map();
  const { Subscription } = getModels();
  const rows = await Subscription.findAll({ where: { userId: { [Op.in]: ids } } });
  return new Map(rows.map((row) => [Number(row.userId), row]));
}

function transactionIncludes(includeReconciliation) {
  const { User, SubscriptionPlan, PaymentEvent } = getModels();
  return [
    { model: User, as: 'user', attributes: ['id', 'name', 'email'], required: true },
    { model: SubscriptionPlan, as: 'plan', attributes: ['id', 'name', 'displayName'], required: false },
    ...(includeReconciliation ? [{
      model: PaymentEvent,
      as: 'events',
      attributes: ['id', 'providerEventId', 'eventType', 'status', 'processedAt', 'createdAt'],
      required: false,
      separate: true,
      order: [['createdAt', 'DESC'], ['id', 'DESC']],
      limit: 100,
    }] : []),
  ];
}

async function transactions(request, page) {
  const { Payment } = getModels();
  const includeSensitive = request.query.includeSensitive === true;
  const includeReconciliation = request.query.includeReconciliation === true;
  const sortMap = {
    updatedAt: 'updatedAt', createdAt: 'createdAt', status: 'status',
    amountMinor: 'amountMinor', currency: 'currency', paidAt: 'verifiedAt',
  };
  const sortField = sortMap[request.query.sortBy] || 'updatedAt';
  const direction = String(request.query.sortDirection || 'desc').toUpperCase();
  const result = await Payment.findAndCountAll({
    where: transactionWhere(request),
    include: transactionIncludes(includeReconciliation),
    distinct: true,
    subQuery: false,
    limit: page.pageSize,
    offset: page.offset,
    order: [[sortField, direction], ['id', 'DESC']],
  });
  const subscriptions = await subscriptionsFor(result.rows);
  return {
    items: result.rows.map((payment) => transactionJson(request, payment, {
      includeSensitive,
      includeReconciliation,
      subscription: subscriptions.get(Number(payment.userId)),
    })),
    pagination: {
      page: page.page,
      pageSize: page.pageSize,
      totalItems: result.count,
      totalPages: Math.ceil(result.count / page.pageSize),
    },
  };
}

async function transaction(request, transactionId) {
  const { Payment } = getModels();
  const includeSensitive = request.query.includeSensitive === true;
  const includeReconciliation = request.query.includeReconciliation === true;
  const payment = await Payment.findByPk(transactionId, {
    include: transactionIncludes(includeReconciliation),
  });
  if (!payment) return null;
  const subscriptions = await subscriptionsFor([payment]);
  if (includeSensitive || includeReconciliation) {
    await recordAudit({
      request,
      administratorId: request.admin.id,
      action: 'admin.payments.transaction.read',
      targetType: 'payment',
      targetId: payment.id,
      metadata: { includeSensitive, includeReconciliation },
    });
  }
  return transactionJson(request, payment, {
    includeSensitive,
    includeReconciliation,
    subscription: subscriptions.get(Number(payment.userId)),
  });
}

module.exports = { plans, plan, transactions, transaction, planJson, transactionJson };
