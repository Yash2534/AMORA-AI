# Phase 5 P-20/P-26 Runtime Evidence

## Evidence metadata

- Date/time: 2026-10-09 (Asia/Calcutta)
- Commit at validation start: `eeeee8165714976a4cdad7d5a1dd460907c9bbf9`
- Branch: `security/amoraa-pending-remediation`
- Working directory: `D:\Projects\amora_ai`
- Node.js: `v20.19.5`
- npm: `10.8.2`
- Flutter: `3.44.6` stable, framework revision `ee80f08bbf`
- Dart: `3.12.2`
- Test data: disposable randomized local users, local OTP rows, dummy phone numbers and local MariaDB records
- Production accessed: **NO**
- Staging/cloud/provider consoles accessed: **NO**
- Real customer data or production credentials used: **NO**
- Controls: P-20, P-26

## Dedicated P-20/P-26 integration run

Command:

`node --test --test-concurrency=1 test/phase5-security.integration.test.js`

Working directory: `D:\Projects\amora_ai\Backend`

Final result: exit code 0; **6 passed, 0 failed, 0 skipped**; runner duration **5208.7774 ms**.

Passing cases:

1. Phone normalization canonicalizes supported Indian formatting and rejects invalid input.
2. Local deactivation requires password, revokes sessions/devices, and old credentials stay invalid after reactivation.
3. Google deactivation requires a freshly verified matching provider identity and supports reactivation.
4. Phone change requires step-up, new-number OTP, uniqueness, and revokes existing sessions.
5. Expired phone-change OTP is denied and the database is the final duplicate-ownership boundary.
6. Concurrent verified claims cannot create duplicate phone ownership.

Earlier corrective runs are not concealed:

- The first sandboxed run could not connect to loopback MariaDB (`EACCES 127.0.0.1:3306`); this was an execution-environment block, not a product assertion failure.
- The first unrestricted fixture run failed its setup because the disposable user supplied `NULL` to the existing non-null phone column. The fixture was corrected to use the application's no-phone representation.
- A later setup exposed a retained dummy-number collision. Randomized disposable phone fixtures were introduced so reruns remain isolated.
- The test originally expected an outbound SMS in test mode, but the application intentionally suppresses delivery in test mode. It now proves the persisted OTP record and confirmation behavior instead of weakening delivery safeguards.
- The concurrent-claim test exposed an unhandled database deadlock path returning 500. The controller now maps the losing ownership transaction to a controlled 409 conflict while the database unique boundary remains authoritative. The unchanged security assertion then passed.

## Focused regression run

Command:

`node --test --test-concurrency=1 test/phase5-security.integration.test.js test/auth-onboarding.integration.test.js test/google-signup-consent.integration.test.js test/relationships.integration.test.js test/security-remediation.unit.test.js`

Working directory: `D:\Projects\amora_ai\Backend`

Result: exit code 0; **34 passed, 0 failed, 0 skipped**; runner duration **18798.6451 ms**.

This run covered the new lifecycle behavior together with signup/onboarding, Google identity handling, discovery/relationships and security-event classification.

## Backend full regression

Command: `npm test`

Working directory: `D:\Projects\amora_ai\Backend`

Result: exit code 0; **356 passed, 0 failed, 0 skipped, 0 todo**; runner duration **191539.0293 ms**.

## Flutter validation

Targeted command: `flutter test test/account_actions_test.dart`

Result: exit code 0; **22 passed, 0 failed**. The new Google-account test proves the deactivation screen requests provider reauthentication without presenting a password field.

Full command: `flutter test`

Result: exit code 0; **659 passed, 0 failed, 14 skipped**. Exact runner duration was not retained in the command transcript and is therefore not asserted.

Static command: `flutter analyze`

Result: exit code 1; **44 pre-existing warnings/info**. No finding was reported in a Phase 5 file. The analyzer result is recorded as non-passing and was not hidden or relabeled as a pass.

Format command:

`dart format --output=none --set-exit-if-changed lib/core/auth/auth_service.dart lib/core/api/phase_two_api_service.dart lib/features/settings/presentation/account_action_screens.dart test/account_actions_test.dart`

Result: exit code 0; 4 files checked, 0 changed.

## Static source validation

- `node --check` was executed for all new and modified Phase 5 JavaScript source/test files: exit code 0.
- `git diff --check`: exit code 0; line-ending notices were informational and no whitespace error was reported.
- Focused direct-console/sensitive-logger search across the new phone/deactivation implementation returned no matching sensitive output path.

## Control conclusion

- **P-20: COMPLETE — VERIFIED.** Repository exit criteria are demonstrated for local-password and Google-provider users, step-up denial, state transition, refresh/device revocation, stale access/refresh rejection, discovery exclusion, reactivation and audit-safe behavior. A real configured-provider staging journey remains secondary release evidence.
- **P-26: IMPLEMENTED — OPERATIONS/POLICY SIGNOFF REQUIRED.** Repository behavior is demonstrated for canonicalization, OTP purpose/expiry/replay, uniqueness, concurrent ownership, step-up, notification and session/device revocation. Product/Security/Support policy approval and real SMS-provider staging evidence are absent and were not fabricated.

