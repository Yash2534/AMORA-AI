const { runtimeConfiguration } = require('../services/platformSettingsService');

module.exports = async (req, res, next) => {
  try {
    const settings = await runtimeConfiguration();
    if (!settings.maintenance_mode_enabled) return next();
    return res.status(503).json({ success: false, message: 'The application is temporarily unavailable for maintenance.', code: 'APP_MAINTENANCE', errors: [] });
  } catch (error) { return next(error); }
};
