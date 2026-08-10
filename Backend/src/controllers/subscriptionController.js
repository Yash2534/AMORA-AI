const { getModels } = require('../models');
const { planJson, subscriptionJson, currentSubscription } = require('../services/entitlementService');

exports.plans = async (_req, res, next) => {
  try {
    const { SubscriptionPlan } = getModels();
    const plans = await SubscriptionPlan.findAll({ where: { active: true }, order: [['sortOrder', 'ASC'], ['id', 'ASC']] });
    return res.json({ success: true, message: 'Subscription plans retrieved.', data: { plans: plans.map(planJson) } });
  } catch (error) { return next(error); }
};

exports.me = async (req, res, next) => {
  try { return res.json({ success: true, message: 'Membership retrieved.', data: { membership: subscriptionJson(await currentSubscription(req.user.sub)) } }); }
  catch (error) { return next(error); }
};

exports.cancel = async (req, res, next) => {
  try {
    const subscription = await currentSubscription(req.user.sub);
    if (!subscription || !['active', 'trialing', 'cancelled'].includes(subscription.status)) return res.status(409).json({ success: false, message: 'There is no renewable membership to cancel.', code: 'SUBSCRIPTION_NOT_ACTIVE', errors: [] });
    if (!subscription.cancelAtPeriodEnd) await subscription.update({ status: 'cancelled', autoRenew: false, cancelAtPeriodEnd: true, cancelledAt: new Date() });
    await subscription.reload({ include: [{ model: getModels().SubscriptionPlan, as: 'plan' }] });
    return res.json({ success: true, message: 'Membership renewal cancelled.', data: { membership: subscriptionJson(subscription), effectiveCancellationDate: subscription.currentPeriodEnd } });
  } catch (error) { return next(error); }
};

exports.restore = async (req, res, next) => {
  try {
    const subscription = await currentSubscription(req.user.sub);
    return res.json({ success: true, message: subscription ? 'Membership restored from server state.' : 'No membership is available to restore.', data: { membership: subscriptionJson(subscription) } });
  } catch (error) { return next(error); }
};
