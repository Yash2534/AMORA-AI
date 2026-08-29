# Amora AI backend

Standalone Node.js/Express authentication API for the Amora AI mobile client. All server code lives in this folder; it does not modify or depend on the Flutter project.

## Zero-config XAMPP quickstart

1. Start **Apache** and **MySQL** in the XAMPP Control Panel. The provided defaults expect MySQL at `localhost:3306`, user `root`, with an empty password.
2. In this `Backend` folder, run:

```bash
npm install
npm run db:migrate
npm run dev
```

On first setup, the migration command creates the configured database when permitted and applies the ordered migrations recorded in `SequelizeMeta`. The server only connects to the migrated schema; it does not call `sequelize.sync()` or mutate tables at startup. In development with no SMS provider configured, OTPs print in the terminal and are returned as `devOtp` in the successful OTP-generating response. This makes the whole flow testable in Postman without external accounts.

## Fixed OTP for approved non-production environments

Local development, QA, staging, and automated tests may opt into the fixed six-digit OTP by setting:

```dotenv
TEST_FIXED_OTP_ENABLED=true
TEST_FIXED_OTP=111111
TEST_OTP_SKIP_DELIVERY=true
```

The normal signup, resend, and forgot-password endpoints must still create a valid, unexpired `OtpToken` challenge before the fixed value can verify anything. The server continues to enforce identity checks, challenge purpose, expiry, consumption, attempt limits, rate limits, recovery-token rules, and normal session issuance. When delivery skipping is enabled, request and resend responses keep their normal shape but Twilio/SMTP are not called.

Production rejects any configured fixed OTP, enabled fixed-OTP mode, or delivery skipping during startup. Leave all three values disabled/blank in production. The Flutter app contains no fixed-OTP bypass and always submits the entered code to the backend.

Run `npm run db:migrate` as an explicit deployment step before starting a production release. Use `npm run db:migrate:status` to inspect state and `npm run db:migrate:undo` to revert the latest reversible migration.

The Discover integration suite uses `TEST_DB_NAME` and refuses to run against `DB_NAME`:

```bash
npm run test:integration
```

## Docker MySQL alternative

If you prefer Docker rather than XAMPP, run:

```bash
docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=amora_ai --name amora-mysql mysql:8
```

Set `DB_PASS=root` in `.env` before starting the backend. The first MySQL container startup can take a short time.

## Inspecting database records

With XAMPP, open [phpMyAdmin](http://localhost/phpmyadmin), select the `amora_ai` schema, then inspect `Users`, `OtpTokens`, and `RefreshTokens`. Passwords, OTPs, and refresh tokens are stored only as hashes.

## Configure real email and Google sign-in later

For SMTP, set `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_USER`, and `EMAIL_PASS` in `.env`. Ethereal SMTP works well for test email; its preview URL is logged after delivery. For Gmail, use an app password rather than your normal password. Production refuses to start without SMTP configuration.

Set `GOOGLE_CLIENT_IDS` to comma-separated Android and iOS OAuth client IDs. Until then, leave `skip-for-now`; the Google endpoint remains available and returns `GOOGLE_AUTH_NOT_CONFIGURED` (503).

Set `CORS_ORIGIN` to your actual permitted client origin(s), comma-separated, before production.

## Postman walkthrough

Base URL: `http://localhost:5000`

1. `POST /api/auth/signup`

```json
{"name":"Asha Patel","email":"asha@example.com","phoneNumber":"9876543210","password":"StrongPass123","confirmPassword":"StrongPass123","acceptedTerms":true}
```

Copy `devOtp` from the response in ordinary development, or enter `111111` when the guarded fixed-OTP configuration above is enabled.

2. `POST /api/auth/verify-account`

```json
{"phoneNumber":"9876543210","code":"111111"}
```

Save the returned `accessToken` and `refreshToken`.

3. `POST /api/auth/login`

```json
{"email":"asha@example.com","password":"StrongPass123"}
```

4. `GET /api/auth/me` with header `Authorization: Bearer <accessToken>`.

Other endpoints: signup verification resend, password recovery/reset, access-token refresh/rotation, logout, Google sign-in, and profile retrieval are all under `/api/auth`.

## API response shape

Successful responses use `{ "success": true, "message": "...", "data": {} }`. Errors use `{ "success": false, "message": "...", "code": "...", "errors": [] }`. Development OTP responses additionally include `devOtp`; it is strictly omitted outside development.

## Development dummy data

The repeatable dummy-data workflow creates realistic synthetic profiles, development-only local portrait media, discover actions (likes, passes, and Super Likes), Roses, mutual matches, conversations, messages, saved profiles, filters, notification preferences, and a subset of development subscriptions. It never sends email or SMS. All generated accounts use the reserved non-deliverable domain `seed.amoraa.example.test`, and reset removes only that namespace and its dependent records.

The command refuses to run unless all of these conditions are satisfied:

- `NODE_ENV` is `development`, `test`, `qa`, or `staging` (production is always rejected).
- `ALLOW_DUMMY_SEED=true` is set explicitly.
- the exact `DB_NAME` appears in the comma-separated `DUMMY_SEED_DATABASES` allowlist.
- the command contains `--confirm-development-db` (the npm scripts include it).

Configure a local ignored `.env`—never a production environment—with values such as:

```dotenv
ALLOW_DUMMY_SEED=true
DUMMY_SEED_DATABASES=amora_ai,amora_ai_test
SEED_USER_COUNT=150
SEED_RANDOM_SEED=12345
SEED_REFERENCE_DATE=2026-08-29
SEED_TEST_PASSWORD=Amoraa-Dev-Only-2026!
```

Then run:

```bash
npm run setup:demo-portrait-assets
npm run db:seed:dummy
npm run db:seed:dummy:validate
npm run verify:dummy-seed
npm run verify:demo-profile-images
```

`setup:demo-portrait-assets` caches 200 CC0 AI-generated portraits from the Faker person-portrait collection under `demo-assets/`. The seed combines those assets with the repository-owned synthetic portraits and writes exactly two unique images for each of the 150 completed demo profiles. The application never fetches portrait media at runtime.

`db:seed:dummy` is deterministic and idempotent: it removes the previous isolated seed dataset and recreates it in one database transaction. To remove only generated dummy data and its prefixed local media:

```bash
npm run db:seed:dummy:reset
```

The predictable video accounts are:

| Role | Login | Scenario |
| --- | --- | --- |
| Demo A — Aisha Mehta | `demo.aisha@seed.amoraa.example.test` | Complete/discoverable; can Like Demo B; already matched with Demo C |
| Demo B — Rohan Shah | `demo.rohan@seed.amoraa.example.test` | Has already liked Demo A, so A's Like creates a real match; receives Super Likes/Roses |
| Demo C — Kavya Iyer | `demo.kavya@seed.amoraa.example.test` | Different age/city for filters; existing long conversation with Demo A |

All three use `SEED_TEST_PASSWORD`. Seeded phone numbers use an internal deterministic pattern and work with the existing guarded development OTP flow; the seeder does not add or invoke any OTP bypass.

The current schema has no coordinates, so discovery returns `distance: null` and true geospatial distance filtering cannot be populated without a future schema/business-logic change. Interests are JSON values validated against the mobile app's existing options rather than lookup-table foreign keys. Super Likes are `DiscoverActions.action = 'superLike'`; there is no separate Super Likes table.
