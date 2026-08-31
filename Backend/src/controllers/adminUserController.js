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

exports.remove = async (req, res, next) => {
  try {
    const user = await service.remove(req, req.params.userId, req.body.reason, req.body.details);
    if (!user) return notFound(req, res);
    return success(req, res, 'User account deleted and identifying data anonymized.', {
      user: { id: String(user.id), status: user.accountStatus },
    });
  } catch (error) { return next(error); }
};

exports.suspend = (req, res) => unavailable(req, res,
  'User suspension requires a schema distinct from the existing deactivated account state.');
exports.loginHistory = async (req, res, next) => {
  try {
    const user = await service.userById(req, req.params.userId);
    if (!user) return notFound(req, res);
    return success(req, res, 'User login history retrieved.', await service.loginHistory(req, user.id, pagination(req.query)));
  } catch (error) { return next(error); }
};
exports.notes = async (req, res, next) => {
  try {
    const user = await service.userById(req, req.params.userId);
    if (!user) return notFound(req, res);
    return success(req, res, 'User notes retrieved.', await service.notes(req, user.id, pagination(req.query)));
  } catch (error) { return next(error); }
};
exports.addNote = async (req, res, next) => {
  try {
    const note = await service.addNote(req, req.params.userId, req.body.text);
    return note ? success(req, res, 'User note added.', { note }) : notFound(req, res);
  } catch (error) { return next(error); }
};
exports.editNote = async (req, res, next) => {
  try {
    const note = await service.editNote(req, req.params.userId, req.params.noteId, req.body.text);
    return note ? success(req, res, 'User note updated.', { note }) : notFound(req, res);
  } catch (error) { return next(error); }
};
exports.deleteNote = async (req, res, next) => {
  try {
    const deleted = await service.deleteNote(req, req.params.userId, req.params.noteId);
    return deleted ? success(req, res, 'User note deleted.', {}) : notFound(req, res);
  } catch (error) { return next(error); }
};
exports.timeline = async (req, res, next) => {
  try {
    const user = await service.userById(req, req.params.userId);
    if (!user) return notFound(req, res);
    return success(req, res, 'User timeline retrieved.', await service.timeline(req, user.id, pagination(req.query)));
  } catch (error) { return next(error); }
};
exports.resetPassword = async (req, res, next) => {
  try {
    const user = await service.requestPasswordReset(req, req.params.userId);
    if (!user) return notFound(req, res);
    return success(req, res, 'Password reset instructions have been sent to the eligible user.', {});
  } catch (error) { return next(error); }
};
