const service = require('../services/adminUserService');
const { pagination } = require('../admin/query');
const { success, failure } = require('../admin/responses');

const notFound = (req, res) => failure(req, res, 404, 'NOT_FOUND', 'User not found.');
const unavailable = (req, res, message) => failure(req, res, 501, 'SCHEMA_NOT_AVAILABLE', message);

exports.list = async (req, res, next) => {
  try {
    const data = await service.users(req, pagination(req.query, { defaultSize: 20 }));
    return success(req, res, 'Users retrieved.', data);
  } catch (error) { return next(error); }
};

exports.details = async (req, res, next) => {
  try {
    const data = await service.details(req, req.params.userId);
    return data ? success(req, res, 'User details retrieved.', data) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.profile = async (req, res, next) => {
  try {
    const data = await service.profile(req, req.params.userId);
    return data ? success(req, res, 'User profile retrieved.', data) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.sessions = async (req, res, next) => {
  try {
    const user = await service.userById(req, req.params.userId);
    if (!user) return notFound(req, res);
    const data = await service.sessions(req, req.params.userId, pagination(req.query));
    return success(req, res, 'User sessions retrieved.', data);
  } catch (error) { return next(error); }
};

exports.activate = async (req, res, next) => {
  try {
    const user = await service.activate(req, req.params.userId);
    if (!user) return notFound(req, res);
    const canonical = await service.userById(req, user.id);
    return success(req, res, 'User activated.', { user: service.summary(req, canonical) });
  } catch (error) { return next(error); }
};

exports.deactivate = async (req, res, next) => {
  try {
    const user = await service.deactivate(req, req.params.userId, req.body.reason);
    if (!user) return notFound(req, res);
    const canonical = await service.userById(req, user.id);
    return success(req, res, 'User deactivated.', { user: service.summary(req, canonical) });
  } catch (error) { return next(error); }
};

exports.forceLogout = async (req, res, next) => {
  try {
    const data = await service.forceLogout(req, req.params.userId);
    return data ? success(req, res, 'User sessions revoked.', { revokedSessions: data.revokedSessions }) : notFound(req, res);
  } catch (error) { return next(error); }
};

exports.suspend = (req, res) => unavailable(req, res,
  'User suspension requires a schema distinct from the existing deactivated account state.');
exports.loginHistory = (req, res) => unavailable(req, res,
  'User login history requires an approved append-only login event table.');
exports.notes = (req, res) => unavailable(req, res,
  'User notes require an approved notes table with author, ownership, version, and retention constraints.');
exports.resetPassword = (req, res) => unavailable(req, res,
  'Administrator-initiated client password reset requires an approved delivery and eligibility policy.');
