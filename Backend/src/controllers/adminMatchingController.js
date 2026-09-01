const service = require('../services/adminMatchingService');
const { success, failure } = require('../admin/responses');

exports.actions = async (req, res, next) => {
  try { return success(req, res, 'Matching actions retrieved.', await service.actions(req, req.query)); } catch (error) { return next(error); }
};
exports.action = async (req, res, next) => {
  try {
    const value = await service.action(req, req.params.actionId);
    if (value?.permissionDenied) return failure(req, res, 403, 'PERMISSION_DENIED', 'Matching action permission is required.');
    return value ? success(req, res, 'Matching action retrieved.', value) : failure(req, res, 404, 'NOT_FOUND', 'Matching action not found.');
  } catch (error) { return next(error); }
};
exports.matches = async (req, res, next) => {
  try { return success(req, res, 'Matches retrieved.', await service.matches(req, req.query)); } catch (error) { return next(error); }
};
exports.match = async (req, res, next) => {
  try { const value = await service.findMatch(req, req.params.matchId); return value ? success(req, res, 'Match retrieved.', value) : failure(req, res, 404, 'NOT_FOUND', 'Match not found.'); } catch (error) { return next(error); }
};
exports.aiScore = async (req, res, next) => {
  try { const value = await service.aiScore(req, req.params.matchId, req.query.includeExplanation === 'true'); return value ? success(req, res, 'Match score retrieved.', value) : failure(req, res, 404, 'NOT_FOUND', 'Match not found.'); } catch (error) { return next(error); }
};
exports.history = async (req, res, next) => {
  try { const match = await service.findMatch(req, req.params.matchId); return match ? success(req, res, 'Match history retrieved.', await service.history(req.params.matchId)) : failure(req, res, 404, 'NOT_FOUND', 'Match not found.'); } catch (error) { return next(error); }
};
