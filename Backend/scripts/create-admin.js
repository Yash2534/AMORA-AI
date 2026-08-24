require('../src/config/bootstrapEnv');
require('../src/config/env');

const bcrypt = require('bcrypt');
const readline = require('readline/promises');
const { stdin, stdout } = require('process');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { recordAudit } = require('../src/services/adminAuditService');

function questionInterface() {
  return readline.createInterface({ input: stdin, output: stdout });
}

async function visibleQuestion(label) {
  const interface_ = questionInterface();
  try {
    return (await interface_.question(label)).trim();
  } finally {
    interface_.close();
  }
}

function hiddenQuestion(label) {
  if (!stdin.isTTY || typeof stdin.setRawMode !== 'function') {
    throw new Error('admin:create requires an interactive terminal so the password can remain hidden.');
  }
  return new Promise((resolve, reject) => {
    let value = '';
    stdout.write(label);
    stdin.setRawMode(true);
    stdin.resume();
    stdin.setEncoding('utf8');
    const cleanup = () => {
      stdin.off('data', onData);
      stdin.setRawMode(false);
      stdin.pause();
    };
    const onData = (character) => {
      if (character === '\u0003') {
        cleanup();
        stdout.write('\n');
        reject(new Error('Administrator creation cancelled.'));
        return;
      }
      if (character === '\r' || character === '\n') {
        cleanup();
        stdout.write('\n');
        resolve(value);
        return;
      }
      if (character === '\u007f' || character === '\b') {
        if (value) {
          value = value.slice(0, -1);
          stdout.write('\b \b');
        }
        return;
      }
      if (character >= ' ' && character <= '~' && value.length < 128) {
        value += character;
        stdout.write('*');
      }
    };
    stdin.on('data', onData);
  });
}

function validatePassword(password) {
  if (password.length < 12) return 'Password must contain at least 12 characters.';
  if (!/[a-z]/.test(password) || !/[A-Z]/.test(password)
    || !/\d/.test(password) || !/[^A-Za-z0-9]/.test(password)) {
    return 'Password must include uppercase, lowercase, number, and symbol characters.';
  }
  return null;
}

async function main() {
  await initializeDatabase();
  const { Administrator, AdminRole } = getModels();

  let email;
  while (!email) {
    const answer = (await visibleQuestion('Email: ')).toLowerCase();
    if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(answer)) email = answer;
    else stdout.write('Enter a valid email address.\n');
  }
  if (await Administrator.findOne({ where: { email } })) {
    throw new Error('An administrator with that email already exists.');
  }

  let password;
  while (!password) {
    const answer = await hiddenQuestion('Password: ');
    const error = validatePassword(answer);
    if (error) stdout.write(`${error}\n`);
    else password = answer;
  }

  let name;
  while (!name) {
    const answer = await visibleQuestion('Name: ');
    if (answer.length >= 2 && answer.length <= 120) name = answer;
    else stdout.write('Name must contain between 2 and 120 characters.\n');
  }

  const roles = await AdminRole.findAll({ where: { isActive: true }, order: [['name', 'ASC']] });
  if (!roles.length) throw new Error('No active administrator roles exist. Run npm run db:migrate first.');
  stdout.write('Available roles:\n');
  roles.forEach((role, index) => stdout.write(`  ${index + 1}. ${role.name} (${role.key})\n`));
  let role;
  while (!role) {
    const answer = await visibleQuestion('Role: ');
    const index = Number(answer) - 1;
    role = roles.find((item) => item.key.toLowerCase() === answer.toLowerCase())
      || (Number.isInteger(index) ? roles[index] : null);
    if (!role) stdout.write('Choose a listed role number or key.\n');
  }

  const passwordHash = await bcrypt.hash(password, 12);
  password = undefined;
  const administrator = await Administrator.sequelize.transaction(async (transaction) => {
    const created = await Administrator.create({ name, email, passwordHash }, { transaction });
    await created.addRole(role, { transaction });
    await recordAudit({
      administratorId: created.id,
      action: 'administrator.created',
      targetType: 'administrator',
      targetId: created.id,
      newValue: { name, email, role: role.key, status: 'active' },
      metadata: { source: 'admin_create_cli' },
      transaction,
    });
    return created;
  });
  stdout.write(`Administrator created successfully: ${administrator.email} (${role.name}).\n`);
}

main()
  .catch((error) => {
    console.error(`Administrator creation failed: ${error.message}`);
    process.exitCode = 1;
  })
  .finally(async () => {
    try {
      await getSequelize().close();
    } catch (_) {
      // Database initialization may have failed before a connection existed.
    }
  });
