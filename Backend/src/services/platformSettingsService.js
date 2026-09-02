const crypto = require('crypto');
const { getModels } = require('../models');
const { recordAudit } = require('./adminAuditService');

const registry = Object.freeze({
  maintenance_mode_enabled: { label: 'Maintenance mode', type: 'boolean', description: 'Temporarily pauses consumer application APIs. Administrator and health APIs remain available.', defaultValue: false },
  registration_enabled: { label: 'New registration', type: 'boolean', description: 'Controls new password and Google account creation.', defaultValue: true },
  support_email: { label: 'Support email', type: 'email', description: 'Public support contact shown by the mobile configuration endpoint.', defaultValue: '' },
});
const cache = { expiresAt: 0, value: null };
const can = (request, permission) => (request.adminPermissions || new Set()).has(permission);
const parsed = (row) => typeof row.value === 'string' ? JSON.parse(row.value) : row.value;
const versionFor = (rows) => `platform_settings_${crypto.createHash('sha256').update(rows.map((row) => `${row.key}:${row.version}`).join('|')).digest('hex').slice(0, 24)}`;
const bad = (message, code = 'VALIDATION_ERROR') => Object.assign(new Error(message), { status: 422, code });

function validate(key, value) {
  const definition = registry[key];
  if (!definition) throw bad(`Unsupported system setting: ${key}.`, 'SETTING_NOT_ALLOWED');
  if (definition.type === 'boolean' && typeof value !== 'boolean') throw bad(`${key} must be a boolean.`);
  if (definition.type === 'email' && (typeof value !== 'string' || (value && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)))) throw bad(`${key} must be a valid email address or empty.`);
}

function payload(request, rows) {
  const sorted = [...rows].sort((a, b) => a.key.localeCompare(b.key));
  return {
    configurationId: 'platform_settings_v1', version: versionFor(sorted),
    settings: sorted.map((row) => ({ key: row.key, label: registry[row.key].label, type: registry[row.key].type, description: registry[row.key].description, value: parsed(row), editable: can(request, 'systemSettings.update'), sensitive: false, updatedAt: row.updatedAt })),
    capabilities: { canEdit: can(request, 'systemSettings.update') },
    discoverConfigurationPath: '/discover/settings',
  };
}

async function rows() {
  const { PlatformSetting } = getModels();
  return PlatformSetting.findAll({ order: [['key', 'ASC']] });
}

async function settings(request) {
  const current = await rows();
  await recordAudit({ request, administratorId: request.admin.id, action: 'admin.system_settings.config_viewed', targetType: 'platform_configuration', targetId: 'platform_settings_v1', metadata: { keys: current.map((row) => row.key) } });
  return payload(request, current);
}

async function update(request, values, expectedVersion) {
  const keys = Object.keys(values || {});
  if (!keys.length) throw bad('At least one system setting is required.');
  keys.forEach((key) => validate(key, values[key]));
  const { PlatformSetting } = getModels();
  return PlatformSetting.sequelize.transaction(async (transaction) => {
    const current = await PlatformSetting.findAll({ order: [['key', 'ASC']], transaction, lock: transaction.LOCK.UPDATE });
    if (String(expectedVersion || '').replaceAll('"', '').trim() !== payload(request, current).version) throw Object.assign(new Error('System settings changed. Refresh before saving.'), { status: 409, code: 'STALE_VERSION' });
    const before = {};
    for (const row of current) if (Object.hasOwn(values, row.key)) {
      before[row.key] = parsed(row);
      await row.update({ value: values[row.key], version: row.version + 1, updatedByAdministratorId: request.admin.id }, { transaction });
    }
    invalidateCache();
    await recordAudit({ request, administratorId: request.admin.id, action: 'admin.system_settings.config_updated', targetType: 'platform_configuration', targetId: 'platform_settings_v1', oldValue: before, newValue: values, transaction });
    return payload(request, await PlatformSetting.findAll({ order: [['key', 'ASC']], transaction }));
  });
}

async function runtimeConfiguration() {
  if (cache.value && cache.expiresAt > Date.now()) return cache.value;
  const configuration = Object.fromEntries(Object.entries(registry).map(([key, definition]) => [key, definition.defaultValue]));
  for (const row of await rows()) configuration[row.key] = parsed(row);
  cache.value = Object.freeze(configuration); cache.expiresAt = Date.now() + 5000;
  return cache.value;
}
function invalidateCache() { cache.value = null; cache.expiresAt = 0; }
module.exports = { registry, settings, update, runtimeConfiguration, invalidateCache };
