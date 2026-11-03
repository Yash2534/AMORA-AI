# Client-QA Staging Deployment Runbook

Audience: the operator with SSH access to `195.35.23.132` and DNS control of `searchenginemonks.com`.

The existing production stack stays untouched throughout: `/root/AMORA-AI`, PM2 `amora-backend`, port 5001, `api.searchenginemonks.com`. Every step below creates something new beside it.

| | Production (untouched) | Client QA staging (new) |
|---|---|---|
| Directory | `/root/AMORA-AI` | `/root/AMORA-AI-CLIENT-STAGING` |
| PM2 | `amora-backend` | `amora-client-staging` |
| Port | 5001 | 5002 |
| NODE_ENV | production | staging |
| DB | existing | `amora_ai_client_staging` / user `amora_client_staging` |
| Host | api.searchenginemonks.com | client-api.searchenginemonks.com |

## 0. Prerequisites (currently BLOCKED)
1. **SSH:** key-based root (or sudo) access from the operator machine. Password auth was rejected for this workstation, which has no key.
2. **DNS:** an `A` record `client-api.searchenginemonks.com → 195.35.23.132`. It currently returns NXDOMAIN.
3. **QA phone:** the approved client QA number(s) for the OTP allowlist.

## 1. Read-only inspection
```bash
hostnamectl; cat /etc/os-release; df -h; free -h
pm2 status; nginx -t; ss -lntup
ss -lntp | grep ':5002 ' && echo "PORT 5002 IN USE: STOP"
```

## 2. Staging database (new schema and user only)
```bash
STAGING_DB_PASS="$(openssl rand -base64 36 | tr -d '/+=' | cut -c1-40)"   # never echo it
mysql -u root -p <<SQL
CREATE DATABASE amora_ai_client_staging CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE amora_ai_client_staging_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'amora_client_staging'@'localhost' IDENTIFIED BY '${STAGING_DB_PASS}';
CREATE USER 'amora_client_staging'@'127.0.0.1' IDENTIFIED BY '${STAGING_DB_PASS}';
GRANT ALL PRIVILEGES ON amora_ai_client_staging.*      TO 'amora_client_staging'@'localhost', 'amora_client_staging'@'127.0.0.1';
GRANT ALL PRIVILEGES ON amora_ai_client_staging_test.* TO 'amora_client_staging'@'localhost', 'amora_client_staging'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL
```
The staging user gets no grant on the production schema. No dump of production is ever imported.

## 3. Code and environment
```bash
git clone --branch deploy/client-qa-20261024 https://github.com/Yash2534/AMORA-AI.git /root/AMORA-AI-CLIENT-STAGING
cp /root/AMORA-AI-CLIENT-STAGING/Backend/deploy/client-staging/env.client-staging.example /root/AMORA-AI-CLIENT-STAGING/Backend/.env
chmod 600 /root/AMORA-AI-CLIENT-STAGING/Backend/.env
# Fill every <...> value with an editor. The password variable is DB_PASS.
```
Set `LIVE_TEST_OTP_EXPIRES_AT` to a short window, for example the QA end date at 18:30Z (midnight IST). Keep `TEST_FIXED_OTP_ENABLED`, `TEST_FIXED_OTP` and `TEST_OTP_SKIP_DELIVERY` off or empty.

## 4. Pre-start tests (disposable test schema)
```bash
cd /root/AMORA-AI-CLIENT-STAGING/Backend && npm ci
npm run db:migrate:status
NODE_ENV=test npm test -- test/live-test-otp-config.test.js
NODE_ENV=test npm test -- test/auth-onboarding.integration.test.js
```
Integration tests switch `DB_NAME` to `TEST_DB_NAME` (`amora_ai_client_staging_test`) and refuse to run otherwise.

## 5. Deploy (migrations, PM2, readiness)
```bash
bash /root/AMORA-AI-CLIENT-STAGING/Backend/deploy/client-staging/deploy-client-staging.sh <commit-sha>
pm2 status    # expect amora-backend online AND amora-client-staging online
pm2 describe amora-client-staging | grep -E "status|exec cwd|restarts|uptime|script path"
```
The script aborts on: production directory, production PM2 name, port other than 5002, `NODE_ENV` other than staging, a DB name equal to production's, generic fixed-OTP enabled, or pending migrations after migrate.

## 6. Nginx and TLS
```bash
cp /root/AMORA-AI-CLIENT-STAGING/Backend/deploy/client-staging/nginx-client-api.conf /etc/nginx/sites-available/client-api.searchenginemonks.com
ln -s /etc/nginx/sites-available/client-api.searchenginemonks.com /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
certbot --nginx -d client-api.searchenginemonks.com     # only this name
nginx -t && systemctl reload nginx
```
If the server uses `conf.d/` rather than `sites-*`, place the file in `conf.d/` instead. Do not edit the `api.searchenginemonks.com` block.

## 7. Health validation
Endpoints in `src/server.js`: `/health`, `/health/live`, `/health/ready` (checks DB readiness), `/api/app-config`.
```bash
curl -fsS http://127.0.0.1:5002/health/ready
curl -fsS https://client-api.searchenginemonks.com/health/ready
curl -fsS https://api.searchenginemonks.com/health     # production still healthy
```
WebSocket check: `curl -i -H 'Connection: Upgrade' -H 'Upgrade: websocket' 'https://client-api.searchenginemonks.com/socket.io/?EIO=4&transport=websocket'` must not return 502/404.

## 8. Synthetic QA data
The dummy seeder (`scripts/dummy-seed/config.js`) accepts `NODE_ENV=staging`, but only with `ALLOW_DUMMY_SEED=true`, an explicit `DUMMY_SEED_DATABASES` allowlist, and `--confirm-development-db`. Pass these as one-shot variables. Do not put them in `.env`.
```bash
cd /root/AMORA-AI-CLIENT-STAGING/Backend
ALLOW_DUMMY_SEED=true DUMMY_SEED_DATABASES=amora_ai_client_staging npm run db:seed:dummy
```
`seed-manual-qa-users.js` does not accept `staging` and depends on approved local QA password hashes. Create the client QA user A through the app's signup flow using the allowlisted phone, so that flow is exercised end to end.
Create the QA admin interactively with `node scripts/create-admin.js`. It prompts for a hidden password. Enroll MFA on first login.

## 9. Rollback (staging only)
```bash
pm2 delete amora-client-staging && pm2 save
rm /etc/nginx/sites-enabled/client-api.searchenginemonks.com && nginx -t && systemctl reload nginx
# optional: DROP DATABASE amora_ai_client_staging; DROP USER 'amora_client_staging'@'localhost'; (and @'127.0.0.1')
```
None of these touch `amora-backend`, port 5001, or the production schema.

## Important change vs. current production code
This branch sets `DB_MIGRATION_STARTUP_MODE` to `verify` by default, so the server refuses to start with pending migrations. Any future production rollout of this branch must run `npm run db:migrate` as a release step before restarting. That is out of scope for client QA.
