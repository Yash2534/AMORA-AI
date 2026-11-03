# AMORAA Client QA Release Report

**Classification: NOT READY FOR CLIENT QA.** The code gates pass. The staging backend could not be deployed because SSH access and DNS are missing (see §14).

| # | Item | Value |
|---|---|---|
| 1 | Date | 2026-10-24 |
| 2 | Main branch | `deploy/client-qa-20261024` (from `security/amoraa-pending-remediation` @ `ea41d4ef`) |
| 3 | Main SHA | `1bf2b3795db19e9fb12ad20afe3caab305785c41`, pushed to origin. Later commits on this branch change only docs. |
| 4 | Admin Web | `amoraa_admin_web` `main` @ `d300aaf`. Audited, not deployed. |
| 5 | Backend tests | 386 / 386 pass, 0 fail, 0 skipped, 204 s |
| 6 | Flutter analyze | No issues found (was 44) |
| 7 | Flutter tests | 659 passed, 14 skipped, 0 failed |
| 8 | Staging API URL | `https://client-api.searchenginemonks.com` (planned; DNS does not exist yet) |
| 9 | Staging DB | `amora_ai_client_staging`: **BLOCKED**, not created |
| 10 | PM2 | `amora-client-staging` on :5002: **BLOCKED**, not started |
| 11 | HTTPS | **BLOCKED**: NXDOMAIN, no vhost or certificate |
| 12 | OTP restriction | Verified by automated tests (§12a). Manual staging validation **BLOCKED**. |
| 13 | Smoke tests | **BLOCKED**: no staging backend |
| 16 | APK filename | Not issued. A compile-verification build exists at `build\app\outputs\flutter-apk\app-release.apk`. |
| 17 | SHA-256 (verification build) | `7315978ca257f631d128264ca819a1a3d7e6b6e317031ed26c01f5366c4c6eab` |
| 18 | Size | 95,504,516 bytes (91.1 MB) |
| 19 | Package ID | `com.example.amora_ai` (template ID; see §15) |
| 20 | Version / build | 1.0.0 / 1 |
| 21 | Tested device | None. No device connected; **BLOCKED**. |

## Backend fixes (root causes)
1. **Admin MFA lockout** (≈40 failures, including the cascading Safety, Users, Verification and Management suites). New enforcement rejects sessions that have no `mfaVerifiedAt` once MFA is enrolled. `confirmEnrollment` did not mark the confirming session as verified, so that session was locked out right after proving password and TOTP. The fix stamps that session only, inside the same transaction. Other pre-enrollment sessions stay rejected, and a regression test proves it.
2. **DB_HOST at import.** `config/mailer.js` eagerly loaded `env.js`, which validates at module load. It now resolves lazily. `server.js` and `migrations/run.js` still validate strictly at startup.
3. **Withdrawal error code.** The 5xx hardening also hid curated domain codes. Now a 5xx returns its code only when `expose === true`, and everything else stays `INTERNAL_ERROR`. Marked as exposed: `WITHDRAWAL_PROCESSING_FAILED`, `RESET_DELIVERY_FAILED`, `PAYMENT_PROVIDER_NOT_CONFIGURED`. Provider request errors stay generic.

No security control was weakened, and no test was skipped, marked TODO, or had assertions removed.

## 12a. OTP restriction evidence (automated)
Production clean config: 111111 is inert. Production with `LIVE_TEST_OTP_*`: fails closed. Staging allowlisted phone: accepted. Non-allowlisted phone: rejected. Expired or malformed config: fails closed. Missing challenge, wrong purpose, expired challenge, replay, and attempt limit: all still enforced (`test/otp-service.test.js`, `test/live-test-otp-config.test.js`, `test/auth-onboarding.integration.test.js`). The OTP never appears in responses, and logs show only masked phones.

## 14. Known blockers
1. **SSH access**: `root@195.35.23.132` rejects this workstation (`publickey,password`), and no key is installed. The server was not inspected or modified.
2. **DNS**: no record exists for `client-api.searchenginemonks.com`.
3. **QA phone allowlist**: the approved number has not been provided. It belongs only in the server `.env`.
4. **Physical Android device**: none connected.
5. **Release signing**: no production keystore exists. The build is signed with a separate key created for this purpose, `CN=AMORAA CLIENT QA ONLY - NOT FOR PLAY STORE`, stored outside the repo at `D:\Projects\amoraa_client_qa_signing\`. A later Play Store build signed with the real key will need an uninstall first.
6. **Admin staging**: needs its own host (DNS and server) and must be included in `CORS_ORIGIN`.

## 15. Provider and other limitations
- SMS, email, push (Firebase) and Razorpay credentials are not configured for staging. Only the allowlisted phone skips SMS delivery, so non-allowlisted signup on staging fails at delivery unless a sandbox SMS provider is added.
- The package ID is still the Flutter template `com.example.amora_ai`. That is acceptable for internal QA, but it must change before any store release.
- `DB_MIGRATION_STARTUP_MODE` now defaults to `verify`. Any production rollout of this branch must run `npm run db:migrate` before restarting.
- Live production (`api.searchenginemonks.com`) serves `/health` but not `/health/ready`, so it runs older code than this branch.

## 22. Flow status
Code gates: PASS. Staging deployment, OTP manual tests A–F, QA accounts, smoke flows (auth, onboarding, profile, discovery, reactions, match, chat, notifications, safety, account, verification, admin, payments), and device tests: all **BLOCKED** on §14.

## 23. Rollback
- Code: production still runs from `/root/AMORA-AI`, which was untouched. The branch can be abandoned.
- Staging, once created: see `STAGING_DEPLOYMENT_RUNBOOK.md` §9 (delete the PM2 app, remove the vhost, optionally drop the staging schema).

## 24. Production impact statement
No production server, process, database, nginx configuration, DNS or user was accessed or modified. No production customer data was used. No OTP bypass was enabled anywhere.

## Next steps to reach READY FOR CLIENT QA
1. Provide key-based SSH access and create the DNS `A` record.
2. Follow `STAGING_DEPLOYMENT_RUNBOOK.md` using commit `1bf2b379` and the approved allowlisted phone.
3. Run manual OTP tests A–F and the smoke flows, and create the synthetic QA accounts.
4. Rebuild the APK (the same command works once the hostname resolves), copy it to `AMORAA_Client_Test_<date>.apk`, and run the device tests over Wi-Fi and mobile data with no USB connected.
