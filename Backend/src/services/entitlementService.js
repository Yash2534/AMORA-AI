const { getModels } = require('../models');

function jsonArray(value) {
  if (Array.isArray(value)) return value;
  if (typeof value !== 'string') return [];
  try {
    const decoded = JSON.parse(value);
    return Array.isArray(decoded) ? decoded : [];
  } catch (_) {
    return [];
  }
}

function jsonObject(value) {
  if (value && typeof value === 'object' && !Array.isArray(value)) return value;
  if (typeof value !== 'string') return {};
  try {
    const decoded = JSON.parse(value);
    return decoded && typeof decoded === 'object' && !Array.isArray(decoded) ? decoded : {};
  } catch (_) {
    return {};
  }
}

function addPeriod(start, unit, interval) {
  const value = new Date(start);
  if (unit === 'day') value.setUTCDate(value.getUTCDate() + interval);
  else if (unit === 'week') value.setUTCDate(value.getUTCDate() + (interval * 7));
  else if (unit === 'year') value.setUTCFullYear(value.getUTCFullYear() + interval);
  else value.setUTCMonth(value.getUTCMonth() + interval);
  return value;
}

function planJson(plan) {
  if (!plan) return null;
  const priceMinor = Number(plan.priceMinor);
  return { id: plan.id, name: plan.name, displayName: plan.displayName, description: plan.description, priceMinor, price: priceMinor / 100, currency: plan.currency, billingPeriod: plan.billingPeriod, billingInterval: Number(plan.billingInterval), features: jsonArray(plan.features), entitlements: jsonObject(plan.entitlements), trialDays: Number(plan.trialDays || 0), offerText: plan.offerText, active: Boolean(plan.active), sortOrder: Number(plan.sortOrder || 0) };
}

function subscriptionJson(subscription) {
  if (!subscription) return { id: null, planId: null, status: 'none', plan: null, startedAt: null, currentPeriodStart: null, currentPeriodEnd: null, renewalDate: null, autoRenew: false, cancelAtPeriodEnd: false, cancelledAt: null, endedAt: null, entitlements: {}, premium: false };
  const plan = subscription.plan || subscription.SubscriptionPlan;
  const accessActive = ['active', 'trialing', 'cancelled'].includes(subscription.status) && new Date(subscription.currentPeriodEnd) > new Date();
  return { id: String(subscription.id), planId: subscription.planId, status: subscription.status, plan: planJson(plan), startedAt: subscription.startedAt, currentPeriodStart: subscription.currentPeriodStart, currentPeriodEnd: subscription.currentPeriodEnd, renewalDate: subscription.autoRenew && !subscription.cancelAtPeriodEnd ? subscription.currentPeriodEnd : null, autoRenew: Boolean(subscription.autoRenew), cancelAtPeriodEnd: Boolean(subscription.cancelAtPeriodEnd), cancelledAt: subscription.cancelledAt, endedAt: subscription.endedAt, entitlements: accessActive ? jsonObject(plan?.entitlements) : {}, premium: accessActive };
}

async function currentSubscription(userId, options = {}) {
  const { Subscription, SubscriptionPlan } = getModels();
  const subscription = await Subscription.findOne({ where: { userId }, include: [{ model: SubscriptionPlan, as: 'plan' }], transaction: options.transaction, lock: options.lock });
  if (subscription && ['active', 'trialing', 'cancelled'].includes(subscription.status) && new Date(subscription.currentPeriodEnd) <= new Date()) {
    await subscription.update({ status: 'expired', endedAt: subscription.currentPeriodEnd, autoRenew: false }, { transaction: options.transaction });
  }
  return subscription;
}

async function activateSubscription(payment, transaction) {
  const { Subscription, SubscriptionPlan } = getModels();
  const plan = await SubscriptionPlan.findByPk(payment.planId, { transaction, lock: transaction.LOCK.UPDATE });
  if (!plan) throw new Error('The purchased subscription plan no longer exists.');
  let subscription = await Subscription.findOne({ where: { userId: payment.userId }, transaction, lock: transaction.LOCK.UPDATE });
  const now = new Date();
  const base = subscription && new Date(subscription.currentPeriodEnd) > now ? new Date(subscription.currentPeriodEnd) : now;
  const currentPeriodEnd = addPeriod(base, plan.billingPeriod, Number(plan.billingInterval));
  const values = { userId: payment.userId, planId: plan.id, status: 'active', provider: payment.provider, startedAt: subscription?.startedAt || now, currentPeriodStart: base, currentPeriodEnd, autoRenew: false, cancelAtPeriodEnd: false, cancelledAt: null, endedAt: null };
  if (subscription) await subscription.update(values, { transaction }); else subscription = await Subscription.create(values, { transaction });
  return subscription;
}

async function hasEntitlement(userId, key, options = {}) {
  const subscription = await currentSubscription(userId, options);
  return subscriptionJson(subscription).entitlements[key] === true;
}

module.exports = { addPeriod, planJson, subscriptionJson, currentSubscription, activateSubscription, hasEntitlement };
