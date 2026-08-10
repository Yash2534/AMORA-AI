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

Copy `devOtp` from the response in development.

2. `POST /api/auth/verify-account`

```json
{"email":"asha@example.com","code":"123456"}
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
