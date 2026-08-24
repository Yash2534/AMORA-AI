const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const catalog = require('../src/admin/permissions');

test('administrator permission catalog is canonical, unique, and covers route guards', () => {
  const keys = catalog.map((permission) => permission.key);
  assert.equal(keys.length, 263);
  assert.equal(new Set(keys).size, keys.length);
  assert.ok(keys.includes('membership.view'));
  assert.ok(keys.includes('membership.manage'));
  assert.ok(!keys.includes('memberships.view'));
  assert.ok(!keys.includes('memberships.manage'));
  for (const permission of catalog) {
    assert.ok(permission.name);
    assert.ok(permission.description);
    assert.equal(permission.module, permission.key.split('.')[0]);
  }

  const routesDirectory = path.resolve(__dirname, '../src/routes');
  const guardedKeys = fs.readdirSync(routesDirectory)
    .filter((file) => file.endsWith('.js'))
    .flatMap((file) => {
      const source = fs.readFileSync(path.join(routesDirectory, file), 'utf8');
      return [...source.matchAll(/require(?:All)?AdminPermission\(([^)]*)\)/g)]
        .flatMap((match) => [...match[1].matchAll(/'([^']+)'/g)].map((item) => item[1]));
    });
  for (const key of guardedKeys) assert.ok(keys.includes(key), `Unknown route permission: ${key}`);
});
