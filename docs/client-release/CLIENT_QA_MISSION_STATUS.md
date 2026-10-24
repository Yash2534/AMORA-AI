# AMORAA Client QA Mission — Running Status

Date: 2026-10-24
Branch at start: `security/amoraa-pending-remediation` @ `ea41d4ef50b3a3be2487fea36b2558ee0ade38c2`

---

## PHASE 1 — Preserve current worktree
- STATUS: PASS
- FILES CHANGED: none in repo
- COMMANDS EXECUTED: `git status`, `git branch --show-current`, `git rev-parse HEAD`, `git diff --stat`, `git diff --binary > backup`, `git ls-files --others --exclude-standard`, `tar -czf`
- RESULT: Snapshot written to `D:\Projects\amora_ai_git_backup\`:
  `worktree_20261024_phase1.patch` (tracked diff, binary-safe), `untracked_20261024_phase1.txt` (1076 untracked paths), `untracked_20261024_phase1.tar.gz`, `head_20261024_phase1.txt`. No destructive git command used.
- BLOCKERS: none
- NEXT ACTION: Phase 2

## PHASE 2 — Investigate 44 backend failures
- STATUS: PASS
- Root-cause clusters:
  - **A. Admin MFA (≈40 failures incl. all cascading Safety/Users/Verification/Management):** working-tree hardening added an access-token check that rejects sessions without `mfaVerifiedAt` once MFA is enrolled (correct). But `confirmEnrollment` never marked the *confirming* session as MFA-verified, so the session that just proved password+TOTP was immediately locked out (`401 TOKEN_REVOKED … requires multi-factor authentication`). Test fixtures that enroll → step-up then aborted before disabling MFA, leaving the shared fixture admin MFA-enabled, producing `202` (challenge) instead of `200` and the `undefined.row` refresh-session error in later tests. **Implementation bug**, not stale tests.
  - **B. DB_HOST import failures (3 files):** `config/mailer.js` eagerly `require('./env')`, which runs full startup validation at module load. Any pure helper importing a controller → otpService → sendEmail → mailer triggered it. **Architecture bug.**
  - **C. Privacy withdrawal (1):** errorHandler hardening (correctly) routes all 5xx to generic `INTERNAL_ERROR`, which also swallowed the intentional curated `WITHDRAWAL_PROCESSING_FAILED` domain code.
- NEXT ACTION: Phase 3

## PHASE 3 — Targeted repair
- STATUS: PASS
- FILES CHANGED:
  - `Backend/src/services/adminMfaService.js` — on successful enrollment confirmation, set `mfaVerifiedAt` on the confirming session (same transaction, only when the session belongs to the same administrator). Other pre-enrollment sessions remain rejected.
  - `Backend/src/config/mailer.js` — resolve `smtpConfigured` lazily inside `getTransport()`. `server.js` and `migrations/run.js` still `require('./config/env')` explicitly at startup → strict validation unchanged.
  - `Backend/src/middleware/errorHandler.js` — 5xx errors are returned with their code only when explicitly curated (`expose === true` strictly, string `code`); everything else stays generic `INTERNAL_ERROR`.
  - `Backend/src/services/withdrawableConsentService.js`, `adminUserService.js` (RESET_DELIVERY_FAILED), `razorpayProvider.js` (PAYMENT_PROVIDER_NOT_CONFIGURED) — mark static-message domain errors `expose: true`. `ProviderRequestError` (may carry provider text) intentionally NOT exposed.
  - Regression tests added:
    - `test/admin-auth.integration.test.js` — "MFA enrollment upgrades only the confirming session and locks out other pre-enrollment sessions"
    - `test/r1-negative-security.unit.test.js` — curated vs. un-curated 5xx; mailer import does not run startup validation (child process with empty env)
    - `test/otp-service.test.js` — live test OTP cannot bypass missing challenge, wrong purpose, exhausted attempts, or elapsed config
- TEST RESULT (targeted): admin-auth 7/7, admin-management 3/3, admin-safety 31/31, admin-users 1/1, admin-verification-decisions 1/1, communicationStyleFilter + r1 + scalability-s1 27/27, privacy-withdrawal 12/12
- BLOCKERS: none

## PHASE 4 — OTP regression
- STATUS: PASS (see Phase 5 full-suite run, which includes all OTP suites)
- Property → evidence:
  1. Prod clean config, 111111 inert → `live-test-otp-config` "clean production configuration gives 111111 no special treatment"; `otp-service` "production gives the configured test value no special treatment"
  2. Prod + LIVE_TEST_OTP_* fails closed → `live-test-otp-config` "production fails closed when any live test OTP variable is configured"
  3. Staging allowlisted, 111111 works → `otp-service` "restricted staging test OTP still requires a valid, unused challenge"; `auth-onboarding` "restricted staging test signup skips SMS only for the allowlisted phone…"
  4. Staging non-allowlisted, 111111 fails → same `otp-service` test (`+919876543211` → OTP_INVALID)
  5. Expired config fails → `live-test-otp-config` "expired, malformed, or empty…"; NEW `otp-service` elapsed-config assertion
  6. Malformed config fails closed → `live-test-otp-config` "expired, malformed, or empty…"
  7. Challenge still required → NEW `otp-service` "…cannot bypass a missing challenge, wrong purpose, or exhausted attempts"
  8. Expired challenge fails → `otp-service` restricted staging test (expired → OTP_EXPIRED, consumed)
  9. Consumed challenge replay fails → same (reuse → OTP_EXPIRED)
  10. Max attempts enforced → NEW `otp-service` test (attempts=5 → OTP_MAX_ATTEMPTS)

## PHASE 5 — Full backend validation
- STATUS: PASS
- COMMAND: `npm test` (node --test --test-concurrency=1)
- RESULT: tests 386 · pass 386 · fail 0 · cancelled 0 · skipped 0 · todo 0 · duration 204.4 s
- Count change 360 → 386 (+26): +22 because three files previously crashed at import (each counted as 1 failed test) and now run their 25 real tests; +4 new regression tests.

## PHASE 6 — Flutter validation
- STATUS: IN PROGRESS
- `flutter pub get` OK. `flutter analyze`: 44 issues in files untouched by this branch (unused imports/elements/params, 2× use_build_context_synchronously, 1 dead null-aware). Cleanup in progress.

## PHASE 7 — API base URL review
- STATUS: PASS (review only, no change)
- `lib/core/config/amora_api_config.dart`: URL comes only from `--dart-define=AMORA_API_BASE_URL`; release builds throw if missing or non-HTTPS; debug falls back to `10.0.2.2:5000` / `localhost:5000`. No hardcoded production host.
- Realtime: socket.io connects to `AmoraApiConfig.baseUrl` (websocket transport) → `wss://` on HTTPS base.
- Media: relative paths are prefixed with `AmoraApiConfig.baseUrl` (onboarding/profile repositories).
- Android release signing requires `AMORAA_ANDROID_KEYSTORE_*` env vars (fails closed). Not present on this machine.

## PHASES 8–25
- STATUS: NOT STARTED
