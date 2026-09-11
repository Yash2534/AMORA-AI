const service = require('../services/adminFinancialService');
const { pagination } = require('../admin/query');
const { success, failure } = require('../admin/responses');

const notFound = (req, res, label) => failure(req, res, 404, 'NOT_FOUND', `${label} not found.`);

exports.plans = async (req, res, next) => {
  try {
    return success(req, res, 'Membership plans retrieved.', await service.plans(req, pagination(req.query, { defaultSize: 20 })));
  } catch (error) { return next(error); }
};

exports.plan = async (req, res, next) => {
  try {
    const data = await service.plan(req, req.params.planId);
    return data ? success(req, res, 'Membership plan retrieved.', { plan: data }) : notFound(req, res, 'Membership plan');
  } catch (error) { return next(error); }
};

exports.createPlan = async (req, res, next) => {
  try {
    const data = await service.createPlan(req, req.body);
    return success(req, res, 'Membership plan created successfully.', { plan: data }, 201);
  } catch (error) { return next(error); }
};

exports.updatePlan = async (req, res, next) => {
  try {
    const data = await service.updatePlan(req, req.params.planId, req.body);
    return data ? success(req, res, 'Membership plan updated successfully.', { plan: data }) : notFound(req, res, 'Membership plan');
  } catch (error) { return next(error); }
};

exports.updatePlanStatus = async (req, res, next) => {
  try {
    const active = req.body.active !== undefined ? req.body.active : req.body.status === 'active';
    const data = await service.updatePlanStatus(req, req.params.planId, active);
    return data ? success(req, res, 'Membership plan status updated.', { plan: data }) : notFound(req, res, 'Membership plan');
  } catch (error) { return next(error); }
};

exports.deletePlan = async (req, res, next) => {
  try {
    const result = await service.deletePlan(req, req.params.planId);
    if (!result.deleted && result.inUse) {
      return failure(req, res, 409, 'PLAN_IN_USE', result.message, [{ field: 'planId', message: result.message }]);
    }
    if (!result.deleted) {
      return notFound(req, res, 'Membership plan');
    }
    return success(req, res, 'Membership plan deleted permanently.', { result });
  } catch (error) { return next(error); }
};

exports.transactions = async (req, res, next) => {
  try {
    return success(req, res, 'Payment transactions retrieved.', await service.transactions(req, pagination(req.query, { defaultSize: 20 })));
  } catch (error) { return next(error); }
};

exports.transaction = async (req, res, next) => {
  try {
    const data = await service.transaction(req, req.params.transactionId);
    return data ? success(req, res, 'Payment transaction retrieved.', { transaction: data }) : notFound(req, res, 'Payment transaction');
  } catch (error) { return next(error); }
};

exports.offers = async (req, res, next) => {
  try {
    return success(req, res, 'Membership offers retrieved.', await service.offers(req, pagination(req.query, { defaultSize: 20 })));
  } catch (error) { return next(error); }
};

exports.offer = async (req, res, next) => {
  try {
    const data = await service.offer(req, req.params.offerId);
    return data ? success(req, res, 'Membership offer retrieved.', { offer: data }) : notFound(req, res, 'Membership offer');
  } catch (error) { return next(error); }
};

exports.createOffer = async (req, res, next) => {
  try {
    const data = await service.saveOffer(req, req.body);
    return success(req, res, 'Discount/Coupon offer created successfully.', { offer: data }, 201);
  } catch (error) { return next(error); }
};

exports.updateOffer = async (req, res, next) => {
  try {
    const data = await service.saveOffer(req, req.body, req.params.offerId);
    return data ? success(req, res, 'Discount/Coupon offer updated successfully.', { offer: data }) : notFound(req, res, 'Membership offer');
  } catch (error) { return next(error); }
};

exports.activateOffer = async (req, res, next) => {
  try {
    const data = await service.activateOffer(req, req.params.offerId);
    return data ? success(req, res, 'Discount/Coupon offer activated successfully.', { offer: data }) : notFound(req, res, 'Membership offer');
  } catch (error) { return next(error); }
};

exports.deactivateOffer = async (req, res, next) => {
  try {
    const data = await service.deactivateOffer(req, req.params.offerId);
    return data ? success(req, res, 'Discount/Coupon offer deactivated successfully.', { offer: data }) : notFound(req, res, 'Membership offer');
  } catch (error) { return next(error); }
};

exports.deleteOffer = async (req, res, next) => {
  try {
    const result = await service.deleteOffer(req, req.params.offerId);
    return result ? success(req, res, 'Membership offer deleted successfully.', { result }) : notFound(req, res, 'Membership offer');
  } catch (error) { return next(error); }
};

exports.subscriptions = async (req, res, next) => {
  try {
    return success(req, res, 'Membership subscriptions retrieved.', await service.subscriptions(req, pagination(req.query, { defaultSize: 20 })));
  } catch (error) { return next(error); }
};

exports.subscription = async (req, res, next) => {
  try {
    const data = await service.subscription(req, req.params.subscriptionId);
    return data ? success(req, res, 'Membership subscription retrieved.', { subscription: data }) : notFound(req, res, 'Membership subscription');
  } catch (error) { return next(error); }
};

exports.planSubscribers = async (req, res, next) => {
  try {
    const data = await service.planSubscribers(req, req.params.planId, pagination(req.query, { defaultSize: 20 }));
    return data ? success(req, res, 'Plan subscribers retrieved.', data) : notFound(req, res, 'Membership plan');
  } catch (error) { return next(error); }
};

exports.processRefund = async (req, res, next) => {
  try {
    const data = await service.processRefund(req, req.params.transactionId, req.body);
    return success(req, res, 'Refund processed successfully.', { refund: data });
  } catch (error) {
    if (error.message && error.message.includes('not found')) {
      return failure(req, res, 404, 'NOT_FOUND', error.message);
    }
    if (error.message && error.message.includes('not eligible')) {
      return failure(req, res, 400, 'REFUND_INELIGIBLE', error.message);
    }
    return next(error);
  }
};

exports.offerUsage = async (req, res, next) => {
  try {
    const data = await service.offerUsage(req, req.params.offerId, pagination(req.query, { defaultSize: 20 }));
    return success(req, res, 'Offer usage history retrieved.', data);
  } catch (error) { return next(error); }
};

exports.offerAnalytics = async (req, res, next) => {
  try {
    const data = await service.offerAnalytics(req, req.params.offerId);
    return data ? success(req, res, 'Offer analytics retrieved.', { analytics: data }) : notFound(req, res, 'Membership offer');
  } catch (error) { return next(error); }
};

exports.revenueOverview = async (req, res, next) => {
  try {
    const data = await service.revenueOverview(req);
    return success(req, res, 'Revenue command center metrics retrieved.', data);
  } catch (error) { return next(error); }
};

exports.revenueTrace = async (req, res, next) => {
  try {
    const data = await service.revenueTrace(req, req.params.targetId);
    return data ? success(req, res, 'Transaction trace retrieved.', { trace: data }) : notFound(req, res, 'Transaction trace');
  } catch (error) { return next(error); }
};

exports.reconciliation = async (req, res, next) => {
  try {
    const data = await service.reconciliationList(req, pagination(req.query, { defaultSize: 20 }));
    return success(req, res, 'Financial reconciliation records retrieved.', data);
  } catch (error) { return next(error); }
};

exports.investigateMismatch = async (req, res, next) => {
  try {
    const data = await service.investigateMismatch(req, req.params.transactionId, req.body || {});
    return data ? success(req, res, 'Investigation logged successfully.', { investigation: data }) : notFound(req, res, 'Payment transaction');
  } catch (error) { return next(error); }
};



