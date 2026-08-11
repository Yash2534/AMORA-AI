const { filtersFor, updateFilters } = require('../services/discoverPreferenceService');

exports.get = async (req, res, next) => {
  try {
    return res.json({
      success: true,
      message: 'Account preferences retrieved.',
      data: { preferences: await filtersFor(req.user.sub) },
    });
  } catch (error) { return next(error); }
};

exports.update = async (req, res, next) => {
  try {
    const current = await filtersFor(req.user.sub, req.body);
    if (current.minAge > current.maxAge) {
      return res.status(400).json({
        success: false,
        message: 'Minimum age cannot exceed maximum age.',
        code: 'VALIDATION_ERROR',
        errors: [{ field: 'minAge', message: 'Minimum age cannot exceed maximum age.' }],
      });
    }
    return res.json({
      success: true,
      message: 'Account preferences updated.',
      data: { preferences: await updateFilters(req.user.sub, req.body) },
    });
  } catch (error) { return next(error); }
};
