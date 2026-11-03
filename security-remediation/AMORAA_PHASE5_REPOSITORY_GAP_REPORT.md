# AMORAA Phase 5 Repository Gap Closure Report

## 1. Outcome

Phase 5 addressed only P-20 and P-26. Both repository implementation gaps are closed and the full local regressions pass. P-20 satisfies its repository exit criteria and is **COMPLETE — VERIFIED**. P-26 is **IMPLEMENTED — OPERATIONS/POLICY SIGNOFF REQUIRED** because the repository cannot approve phone reassignment/recovery policy or prove real SMS-provider behavior.

No production, staging, cloud console, provider console, real customer data or production credential was accessed.

## 2. P-20 — deactivation lifecycle

Implemented and verified:

- provider-neutral step-up: local accounts verify the current password; Google accounts verify a fresh Google ID token;
- the verified Google subject and email must match the stored account identity;
- deactivation atomically changes status, increments token version, deletes refresh sessions and registered devices, and writes sanitized audit events;
- existing access and refresh credentials are rejected after deactivation and remain invalid after reactivation;
- deactivated users are excluded by the canonical account-status/session policy;
- reactivation uses a fresh authenticated session; cross-user identifiers in the request do not change the target account;
- self-service, admin and safety deactivation paths revoke devices/sessions consistently;
- the Flutter flow presents provider reauthentication for Google accounts instead of requesting a nonexistent local password.

Status: **COMPLETE — VERIFIED**.

Residual release evidence: exercise the same journey against a real configured identity provider in staging and retain sanitized device/session evidence. This is not represented as already performed.

## 3. P-26 — phone lifecycle

Implemented and verified:

- one shared canonicalizer accepts the current product's supported Indian mobile formats and stores `+91XXXXXXXXXX`;
- a migration normalizes recognized stored values, detects collisions, and creates a generated nonblank phone identity with a unique database index;
- request and confirmation routes require authentication and fresh password/provider step-up;
- the new phone number receives a dedicated `phone_change` OTP with expiry, one-time use and replay denial;
- ownership is rechecked inside the transaction, with the database uniqueness boundary as the final race-safe authority;
- concurrent verified claims produce one success and one controlled conflict, never duplicate ownership;
- a successful change increments token version, deletes refresh sessions/devices, emits sanitized audit metadata and sends an account notification without logging the raw number/OTP;
- expired/wrong OTPs and already-owned numbers are denied without transferring ownership.

Status: **IMPLEMENTED — OPERATIONS/POLICY SIGNOFF REQUIRED**.

The draft in `PHONE_NUMBER_REASSIGNMENT_POLICY_DRAFT.md` explicitly requires Product/Security/Support approval for lost, recycled and disputed numbers, recovery evidence, escalation, privacy and support handling. Real SMS-provider delivery and support operations were not tested.

## 4. Files changed for Phase 5

Backend implementation/tests:

- `Backend/src/utils/phoneNumber.js`
- `Backend/src/policies/accountStatusPolicy.js`
- `Backend/src/services/providerReauthenticationService.js`
- `Backend/src/migrations/202610090003-harden-phone-ownership.js`
- `Backend/src/models/OtpToken.js`
- `Backend/src/controllers/accountController.js`
- `Backend/src/controllers/authController.js`
- `Backend/src/routes/accountRoutes.js`
- `Backend/src/routes/authRoutes.js`
- `Backend/src/middleware/authMiddleware.js`
- `Backend/src/middleware/securityEventMiddleware.js`
- `Backend/src/realtime/realtimeHub.js`
- `Backend/src/services/adminUserService.js`
- `Backend/test/phase5-security.integration.test.js`
- `Backend/test/security-remediation.unit.test.js`

Flutter implementation/tests:

- `lib/core/auth/auth_service.dart`
- `lib/core/api/phase_two_api_service.dart`
- `lib/features/settings/presentation/account_action_screens.dart`
- `test/account_actions_test.dart`

Evidence/reconciliation:

- `security-remediation/PHONE_NUMBER_REASSIGNMENT_POLICY_DRAFT.md`
- `security-remediation/evidence/tests/phase5/phase5-p20-p26.md`
- `security-remediation/AMORAA_ACTUAL_VERIFICATION_STATUS.md`
- `security-remediation/AMORAA_SECURITY_REAL_VERIFICATION_REPORT.md`
- `security-remediation/MANUAL_VERIFICATION_REGISTER.md`
- `security-remediation/PRODUCTION_SECURITY_RELEASE_GATE.md`
- `security-remediation/AMORAA_PHASE5_REPOSITORY_GAP_REPORT.md`

## 5. Runtime and static results

- Dedicated Phase 5 backend: **6 passed, 0 failed**.
- Focused backend security/auth/discovery: **34 passed, 0 failed**.
- Full backend: **356 passed, 0 failed, 0 skipped/blocked**.
- Targeted Flutter account actions: **22 passed, 0 failed**.
- Full Flutter: **659 passed, 0 failed, 14 skipped**.
- Flutter analysis: exit 1 with **44 pre-existing warnings/info**; no Phase 5 file finding.
- JavaScript syntax checks: exit 0.
- Dart format check: exit 0.
- Git diff whitespace check: exit 0.

The implementation/test iterations that initially failed and the corresponding corrections are recorded in the Phase 5 evidence file. No test was disabled or weakened to manufacture a pass.

## 6. Reconciled counts

- Previously complete: **6**
- Newly complete: **1** (P-20)
- Total COMPLETE — VERIFIED: **7**
- Repository gaps remaining: **0**
- P0: **6 complete / 29 open**
- P1: **1 complete / 14 open**
- P2: **0 complete / 1 open**
- Manual-evidence primary status: **5**
- Staging-evidence primary status: **3**
- Infrastructure-evidence primary status: **13**
- Operations/policy-signoff primary status: **1** (P-26)
- Legal blockers: **10**
- Management blockers: **10**
- Independent VAPT blockers: **2**

The primary categories are mutually exclusive and total 51 controls.

## 7. Production recommendation

**READY FOR NEXT SECURITY VALIDATION STAGE — NOT PRODUCTION READY.**

P-26 policy/provider proof, all other manual/staging/infrastructure/legal/management gates, and P-46/P-47 independent VAPT/retest remain open. Local repository closure is not production evidence.

