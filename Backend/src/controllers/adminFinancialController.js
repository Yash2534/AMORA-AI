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
