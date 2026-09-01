const service = require('../services/adminDiscoverConfigurationService');
const { success, failure } = require('../admin/responses');

exports.settings = async (req, res, next) => { try { return success(req, res, 'Discover settings retrieved.', await service.settings(req)); } catch (error) { return next(error); } };
exports.updateSettings = async (req, res, next) => { try { return success(req, res, 'Discover settings updated.', await service.updateSettings(req, req.body.values, req.headers['if-match'] || req.body.expectedVersion)); } catch (error) { return next(error); } };
exports.filters = async (req, res, next) => { try { return success(req, res, 'Discover filter configuration retrieved.', await service.filters(req, req.query.includeSensitive === 'true')); } catch (error) { return next(error); } };
exports.updateFilter = async (req, res, next) => { try { const value = await service.updateFilter(req, req.params.fieldId, req.body, req.headers['if-match'], req.headers['x-field-version']); return value ? success(req, res, 'Discover filter updated.', value) : failure(req, res, 404, 'NOT_FOUND', 'Discover filter not found.'); } catch (error) { return next(error); } };
