#!/usr/bin/env bash
# Deploys the isolated AMORAA client-QA staging backend on the shared VPS.
# Run on the server as: bash deploy-client-staging.sh <git-sha>
#
# Guard rails: refuses to touch the production directory, PM2 process, port,
# or database. Never restarts nginx or amora-backend; only validates nginx.
set -euo pipefail

SHA="${1:?usage: deploy-client-staging.sh <commit-sha>}"
REPO_URL="${REPO_URL:-https://github.com/Yash2534/AMORA-AI.git}"
BRANCH="${BRANCH:-deploy/client-qa-20261024}"
ROOT=/root/AMORA-AI-CLIENT-STAGING
APP="$ROOT/Backend"
PM2_NAME=amora-client-staging
PROD_ROOT=/root/AMORA-AI
PROD_PM2=amora-backend

fail() { echo "[client-staging] ABORT: $*" >&2; exit 1; }

[ "$ROOT" != "$PROD_ROOT" ] || fail "staging root equals production root"
[ "$PM2_NAME" != "$PROD_PM2" ] || fail "staging PM2 name equals production"

if [ ! -d "$ROOT/.git" ]; then
  git clone --branch "$BRANCH" "$REPO_URL" "$ROOT"
fi
git -C "$ROOT" fetch origin "$BRANCH"
git -C "$ROOT" checkout --detach "$SHA"
[ "$(git -C "$ROOT" rev-parse HEAD)" = "$(git -C "$ROOT" rev-parse "$SHA^{commit}")" ] || fail "checkout mismatch"

[ -f "$APP/.env" ] || fail "$APP/.env missing; create it from deploy/client-staging/env.client-staging.example"
chmod 600 "$APP/.env"

envval() { grep -E "^$1=" "$APP/.env" | tail -1 | cut -d= -f2- | tr -d '"'"'"; }
[ "$(envval NODE_ENV)" = "staging" ] || fail "NODE_ENV must be staging"
[ "$(envval PORT)" = "5002" ] || fail "PORT must be 5002"
STAGING_DB="$(envval DB_NAME)"
[[ "$STAGING_DB" == *client_staging* ]] || fail "DB_NAME must be the client staging schema"
PROD_DB="$(grep -E '^DB_NAME=' "$PROD_ROOT/Backend/.env" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d '"'"'" || true)"
[ -z "$PROD_DB" ] || [ "$STAGING_DB" != "$PROD_DB" ] || fail "DB_NAME equals production DB_NAME"
[ "$(envval TEST_FIXED_OTP_ENABLED)" != "true" ] || fail "TEST_FIXED_OTP_ENABLED must stay false"
[ "$(envval TEST_OTP_SKIP_DELIVERY)" != "true" ] || fail "TEST_OTP_SKIP_DELIVERY must stay false"

cd "$APP"
npm ci --omit=dev
echo "[client-staging] Migration status before:"; npm run --silent db:migrate:status | tail -n 5
npm run db:migrate
echo "[client-staging] Migration status after:"; npm run --silent db:migrate:status | grep -c '^up ' | sed 's/^/applied: /'
if npm run --silent db:migrate:status | grep -q '^down '; then fail "pending migrations remain"; fi

if pm2 describe "$PM2_NAME" >/dev/null 2>&1; then
  pm2 reload deploy/client-staging/ecosystem.client-staging.config.js --update-env
else
  pm2 start deploy/client-staging/ecosystem.client-staging.config.js
fi
pm2 save

for attempt in $(seq 1 20); do
  if curl -fsS http://127.0.0.1:5002/health/ready >/dev/null; then
    echo "[client-staging] ready on 127.0.0.1:5002"
    pm2 status
    exit 0
  fi
  sleep 3
done
pm2 logs "$PM2_NAME" --lines 40 --nostream
fail "staging backend did not become ready"
