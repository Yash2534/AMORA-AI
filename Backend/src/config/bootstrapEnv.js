const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const logger = require('../utils/logger');

const backendRoot = path.resolve(__dirname, '../..');
const envPath = path.join(backendRoot, '.env');
const examplePath = path.join(backendRoot, '.env.example');

const existingText = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';
const fileMode = existingText.match(/^NODE_ENV\s*=\s*([^\r\n#]+)/m)?.[1]?.trim();
const runtimeMode = String(process.env.NODE_ENV || fileMode || 'development').toLowerCase();

if (!fs.existsSync(envPath) && runtimeMode === 'development') {
  fs.copyFileSync(examplePath, envPath);
}

let envText = fs.existsSync(envPath) ? fs.readFileSync(envPath, 'utf8') : '';
const placeholders = new Set(['', 'changeme', 'change-me', 'your-secret', 'replace-me']);
let changed = false;

for (const key of runtimeMode === 'development' ? ['JWT_SECRET', 'JWT_REFRESH_SECRET', 'ADMIN_JWT_SECRET'] : []) {
  const match = envText.match(new RegExp(`^${key}\\s*=\\s*(.*)$`, 'm'));
  const current = match ? match[1].trim().replace(/^['"]|['"]$/g, '') : '';
  if (!match || placeholders.has(current.toLowerCase())) {
    const secret = crypto.randomBytes(64).toString('hex');
    envText = match
      ? envText.replace(new RegExp(`^${key}\\s*=.*$`, 'm'), `${key}=${secret}`)
      : `${envText.trimEnd()}\n${key}=${secret}\n`;
    changed = true;
  }
}

if (changed) {
  fs.writeFileSync(envPath, envText, { mode: 0o600 });
  logger.info('Generated local development JWT secrets.');
}

if (fs.existsSync(envPath)) require('dotenv').config({ path: envPath });
