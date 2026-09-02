const service = require('../services/platformSettingsService');
const { success } = require('../admin/responses');

exports.settings = async (req, res, next) => { try { return success(req, res, 'System settings retrieved.', await service.settings(req)); } catch (error) { return next(error); } };
exports.update = async (req, res, next) => { try { return success(req, res, 'System settings updated.', await service.update(req, req.body.values, req.headers['if-match'] || req.body.expectedVersion)); } catch (error) { return next(error); } };
exports.publicConfiguration = async (_req, res, next) => { try { const settings = await service.runtimeConfiguration(); return res.json({ success: true, data: { maintenanceModeEnabled: settings.maintenance_mode_enabled, registrationEnabled: settings.registration_enabled, supportEmail: settings.support_email || null } }); } catch (error) { return next(error); } };
