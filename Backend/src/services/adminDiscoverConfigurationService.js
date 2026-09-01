const crypto = require('crypto');
const { getModels } = require('../models');
const { recordAudit } = require('./adminAuditService');

const settingsRegistry = Object.freeze({
  default_min_age: { label: 'Default minimum age', type: 'integer', description: 'Minimum age used for new Discover preferences.', minimum: 18, maximum: 99 },
  default_max_age: { label: 'Default maximum age', type: 'integer', description: 'Maximum age used for new Discover preferences.', minimum: 18, maximum: 99 },
  default_max_distance_km: { label: 'Default maximum distance', type: 'integer', description: 'Default distance preference in kilometres.', minimum: 1, maximum: 500 },
  default_minimum_score: { label: 'Default minimum compatibility score', type: 'integer', description: 'Default deterministic compatibility threshold.', minimum: 0, maximum: 100 },
  online_now_window_minutes: { label: 'Online-now window', type: 'integer', description: 'Recent activity window used by the Online now filter.', minimum: 1, maximum: 60 },
});
const runtimeKey = Object.freeze({
  default_min_age: 'minAge', default_max_age: 'maxAge', default_max_distance_km: 'maxDistanceKm',
  default_minimum_score: 'minScore', online_now_window_minutes: 'onlineWindowMinutes',
});
const can = (request, permission) => (request.adminPermissions || new Set()).has(permission);
const cleanVersion = (value) => String(value || '').replaceAll('"', '').trim();
const versionFor = (prefix, rows) => `${prefix}_${crypto.createHash('sha256').update(rows.map((row) => `${row.key || row.id}:${row.version}`).join('|')).digest('hex').slice(0, 24)}`;

function settingValue(row) {
  const value = row.value;
  if (typeof value !== 'string') return value;
  try { return JSON.parse(value); } catch (_) { return value; }
}

function validateSetting(key, value) {
  const definition = settingsRegistry[key];
  if (!definition || !Number.isInteger(value) || value < definition.minimum || value > definition.maximum) {
    const error = new Error(`Invalid value for ${key}.`); error.status = 422; error.code = 'VALIDATION_ERROR'; throw error;
  }
}

function settingsPayload(request, rows) {
  const sorted = [...rows].sort((a, b) => a.key.localeCompare(b.key));
  return {
    configurationId: 'discover_settings_v1',
    version: versionFor('discover_settings', sorted),
    settings: sorted.map((row) => {
      const definition = settingsRegistry[row.key];
      return {
        id: `discover_setting_${row.key}`,
        key: row.key,
        label: definition.label,
        type: definition.type,
        value: settingValue(row),
        description: definition.description,
        minimum: definition.minimum,
        maximum: definition.maximum,
        required: true,
        adminVisible: true,
        sensitive: false,
        editable: can(request, 'discover.settings.manage'),
      };
    }),
    capabilities: { canEdit: can(request, 'discover.settings.manage') },
    updatedAt: sorted.reduce((latest, row) => !latest || row.updatedAt > latest ? row.updatedAt : latest, null),
  };
}

async function settings(request) {
  return settingsPayload(request, await getModels().AdminDiscoverSetting.findAll());
}

async function updateSettings(request, values, expectedVersion) {
  const unknown = Object.keys(values || {}).filter((key) => !settingsRegistry[key]);
  if (unknown.length || !Object.keys(values || {}).length) {
    const error = new Error(unknown.length ? `Unsupported Discover settings: ${unknown.join(', ')}.` : 'At least one setting is required.');
    error.status = 422; error.code = 'VALIDATION_ERROR'; throw error;
  }
  for (const [key, value] of Object.entries(values)) validateSetting(key, value);
  const { AdminDiscoverSetting } = getModels();
  return AdminDiscoverSetting.sequelize.transaction(async (transaction) => {
    const rows = await AdminDiscoverSetting.findAll({ order: [['key', 'ASC']], transaction, lock: transaction.LOCK.UPDATE });
    const current = settingsPayload(request, rows);
    if (cleanVersion(expectedVersion) !== current.version) {
      const error = new Error('Discover settings changed. Refresh before saving.'); error.status = 409; error.code = 'STALE_VERSION'; throw error;
    }
    const before = Object.fromEntries(rows.map((row) => [row.key, settingValue(row)]));
    for (const row of rows) if (Object.hasOwn(values, row.key)) await row.update({ value: values[row.key], version: row.version + 1, updatedByAdministratorId: request.admin.id, updatedAt: new Date() }, { transaction });
    await recordAudit({ request, administratorId: request.admin.id, action: 'admin.discover.settings_updated', targetType: 'discover_configuration', targetId: 'discover_settings_v1', oldValue: before, newValue: values, transaction });
    return settingsPayload(request, await AdminDiscoverSetting.findAll({ order: [['key', 'ASC']], transaction }));
  });
}

function filterPayload(request, rows, includeSensitive) {
  const sorted = [...rows].sort((a, b) => a.displayOrder - b.displayOrder || a.id.localeCompare(b.id));
  return {
    configurationId: 'discover_filters_v1',
    version: versionFor('discover_filters', sorted),
    filters: sorted.filter((row) => includeSensitive || !row.sensitive).map((row) => ({
      id: row.id, key: row.key, label: row.label, type: row.type,
      enabled: row.enabled, visible: row.visible, required: row.required, displayOrder: row.displayOrder,
      maximumSelections: row.maximumSelections, minimumValue: row.minimumValue == null ? null : Number(row.minimumValue), maximumValue: row.maximumValue == null ? null : Number(row.maximumValue),
      supportsSearch: ['text', 'single_selection', 'multiple_selection'].includes(row.type),
      supportsMultipleSelection: row.type === 'multiple_selection', version: `filter_${row.version}`,
      updatedAt: row.updatedAt, adminVisible: true, sensitive: row.sensitive, editable: row.editable && can(request, 'discover.filters.manage'),
    })),
    capabilities: { canEdit: can(request, 'discover.filters.manage'), canReorder: can(request, 'discover.filters.manage') },
    updatedAt: sorted.reduce((latest, row) => !latest || row.updatedAt > latest ? row.updatedAt : latest, null),
  };
}

async function filters(request, includeSensitive) {
  return filterPayload(request, await getModels().AdminDiscoverFilterField.findAll(), includeSensitive);
}

async function updateFilter(request, fieldId, values, configurationVersion, fieldVersion) {
  const allowed = new Set(['enabled', 'visible', 'maximumSelections', 'displayOrder']);
  const unknown = Object.keys(values || {}).filter((key) => !allowed.has(key));
  if (unknown.length || !Object.keys(values || {}).length) {
    const error = new Error(unknown.length ? `Unsupported filter fields: ${unknown.join(', ')}.` : 'At least one filter change is required.'); error.status = 422; error.code = 'VALIDATION_ERROR'; throw error;
  }
  if (Object.hasOwn(values, 'enabled') && typeof values.enabled !== 'boolean') throw Object.assign(new Error('enabled must be boolean.'), { status: 422, code: 'VALIDATION_ERROR' });
  if (Object.hasOwn(values, 'visible') && typeof values.visible !== 'boolean') throw Object.assign(new Error('visible must be boolean.'), { status: 422, code: 'VALIDATION_ERROR' });
  if (Object.hasOwn(values, 'maximumSelections') && values.maximumSelections !== null && (!Number.isInteger(values.maximumSelections) || values.maximumSelections < 1 || values.maximumSelections > 100)) throw Object.assign(new Error('maximumSelections is invalid.'), { status: 422, code: 'VALIDATION_ERROR' });
  if (Object.hasOwn(values, 'displayOrder') && (!Number.isInteger(values.displayOrder) || values.displayOrder < 1 || values.displayOrder > 1000)) throw Object.assign(new Error('displayOrder is invalid.'), { status: 422, code: 'VALIDATION_ERROR' });
  const { AdminDiscoverFilterField } = getModels();
  return AdminDiscoverFilterField.sequelize.transaction(async (transaction) => {
    const rows = await AdminDiscoverFilterField.findAll({ order: [['displayOrder', 'ASC']], transaction, lock: transaction.LOCK.UPDATE });
    const row = rows.find((item) => item.id === fieldId);
    if (!row) return null;
    if (!row.editable) throw Object.assign(new Error('This filter is read-only.'), { status: 409, code: 'FILTER_READ_ONLY' });
    const current = filterPayload(request, rows, true);
    if (cleanVersion(configurationVersion) !== current.version || cleanVersion(fieldVersion) !== `filter_${row.version}`) throw Object.assign(new Error('Discover filters changed. Refresh before saving.'), { status: 409, code: 'STALE_VERSION' });
    if (Object.hasOwn(values, 'maximumSelections') && row.type !== 'multiple_selection') throw Object.assign(new Error('maximumSelections is supported only for multi-select filters.'), { status: 422, code: 'VALIDATION_ERROR' });
    const before = { enabled: row.enabled, visible: row.visible, maximumSelections: row.maximumSelections, displayOrder: row.displayOrder };
    await row.update({ ...values, version: row.version + 1, updatedByAdministratorId: request.admin.id, updatedAt: new Date() }, { transaction });
    await recordAudit({ request, administratorId: request.admin.id, action: 'admin.discover.filter_updated', targetType: 'discover_filter', targetId: row.id, oldValue: before, newValue: values, transaction });
    return filterPayload(request, await AdminDiscoverFilterField.findAll({ transaction }), can(request, 'matching.sensitiveFields.view'));
  });
}

async function runtimeConfiguration() {
  const { AdminDiscoverSetting, AdminDiscoverFilterField } = getModels();
  const [settingsRows, filtersRows] = await Promise.all([AdminDiscoverSetting.findAll(), AdminDiscoverFilterField.findAll({ attributes: ['key', 'enabled'] })]);
  const defaults = {};
  for (const row of settingsRows) defaults[runtimeKey[row.key]] = settingValue(row);
  return { defaults, enabledFilters: new Set(filtersRows.filter((row) => row.enabled).map((row) => row.key)) };
}

module.exports = { settings, updateSettings, filters, updateFilter, runtimeConfiguration };
