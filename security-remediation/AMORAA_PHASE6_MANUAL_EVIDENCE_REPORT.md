# AMORAA Phase 6 Manual Evidence Report

## 1. Outcome

Phase 6 identified all five manual-primary controls and attempted the available local evidence checks. **No control became COMPLETE — VERIFIED.** The environment has no connected Android device, Android virtual device, iOS device, approved staging target, supplied dummy admin credentials, or real Product/Privacy/Security/Support approver.

Production accessed: **NO**. Staging accessed: **NO**. Real customer data and production credentials used: **NO**.

## 2. Manual controls identified

The current `AMORAA_ACTUAL_VERIFICATION_STATUS.md` category—not guesswork—identifies:

1. P-09 — signed mobile-package secret scan;
2. P-16 — mobile permission minimization and device behavior;
3. P-22 — privacy-rights request end-user/operations flow;
4. P-25 — 18+ Flutter journey and underage response policy;
5. P-37 — admin RBAC/MFA/session/audit operational validation.

The fifth manual item is **P-09**.

## 3. Environment discovery

- Branch: `security/amoraa-pending-remediation`
- Commit at attempt: `eeeee8165714976a4cdad7d5a1dd460907c9bbf9`
- ADB: installed; daemon started successfully; `adb devices -l` returned an empty list.
- Android AVDs: none listed by the installed emulator.
- Flutter-visible devices: Windows, Chrome and Edge only; no Android/iOS device.
- Approved staging authorization/endpoints: none supplied.
- Dummy UI/admin accounts and MFA device: none supplied.
- Real human approvals: none supplied.

## 4. P-09 artifact validation

A pre-existing Android APK was available at `build/app/outputs/apk/release/app-release.apk`.

- SHA-256: `5BA137A21454A5C3DCDBA074915D8BB0A919DF55B1BD3D63E6FB105534518FA9`.
- Android `apksigner` verification: signature structurally verifies using v2.
- Signer certificate: `C=US, O=Android, CN=Android Debug`.
- Redacted high-confidence scan: 795 APK entries inspected, 0 skipped for size, 0 matches for private-key material, AWS access keys, Google API keys, Stripe live secrets, GitHub tokens or JWT-like tokens.
- Values are never printed by the scanner.
- No company-signed APK/AAB or IPA was present.

Result: **FAIL / INCOMPLETE — P-09 remains IMPLEMENTED — MANUAL EVIDENCE REQUIRED.** The zero-match bounded scan is useful evidence but cannot compensate for the debug signature, missing iOS/final variants, missing public-identifier review, missing company-key custody and missing human approval. The debug signature also confirms that P-42 remains open.

## 5. P-16 device permissions

Result: **NOT EXECUTED — DEVICE AND APPROVAL EVIDENCE UNAVAILABLE.** No Android/iOS device or AVD exists, so contextual prompts, denial, re-request, selected-photo behavior, crash resistance and user explanation could not be captured. Product/Privacy approval is also absent.

## 6. P-22 privacy request journey

Result: **NOT EXECUTED — MANUAL/STAGING/OPERATIONS/LEGAL EVIDENCE UNAVAILABLE.** Repository integration tests remain supporting evidence, but there was no device, approved staging flow, dummy UI credentials, operational queue evidence or legally approved SLA. No API/UI capture was invented.

## 7. P-25 age-gate journey

Result: **NOT EXECUTED — DEVICE AND POLICY EVIDENCE UNAVAILABLE.** Backend boundary tests remain supporting evidence, but the Android/iOS Flutter journey, screenshots, clear error experience and approved underage response policy could not be proven.

## 8. P-37 admin manual validation

Result: **NOT EXECUTED — ADMIN/STAGING/MANAGEMENT EVIDENCE UNAVAILABLE.** Automated RBAC/MFA/audit tests remain supporting evidence. No safe staging/admin UI, dummy role accounts, MFA test device, roster or human admin-owner approval was supplied.

## 9. P-26 operations/policy signoff

`evidence/manual/P-26/P26_PHONE_REASSIGNMENT_SIGNOFF.md` was created with Product, Security and Support/Operations approver fields plus all required review topics. Every approver remains `TBD — real owner required`, every decision remains `NOT SIGNED`, and SMS-provider staging evidence is absent.

Status remains **IMPLEMENTED — OPERATIONS/POLICY SIGNOFF REQUIRED**.

## 10. Evidence paths

- `evidence/manual/P-09/PHASE6_VALIDATION_RECORD.md`
- `evidence/manual/P-09/scan-apk-redacted.ps1`
- `evidence/manual/P-16/PHASE6_VALIDATION_RECORD.md`
- `evidence/manual/P-22/PHASE6_VALIDATION_RECORD.md`
- `evidence/manual/P-25/PHASE6_VALIDATION_RECORD.md`
- `evidence/manual/P-37/PHASE6_VALIDATION_RECORD.md`
- `evidence/manual/P-26/P26_PHONE_REASSIGNMENT_SIGNOFF.md`

Each record states environment, tester, test-account use, production access, steps, expected/actual result, evidence filename, disposition and remaining dependency. Missing screenshots are explicitly recorded rather than fabricated.

## 11. Recalculated counts

- COMPLETE — VERIFIED: **7**
- Newly complete in Phase 6: **0**
- P0: **6 complete / 29 remaining**
- P1: **1 complete / 14 remaining**
- P2: **0 complete / 1 remaining**
- Manual evidence remaining: **5**
- Staging evidence remaining: **3**
- Infrastructure evidence remaining: **13**
- Operations/policy signoff remaining: **1** (P-26)
- Legal pending: **10**
- Management pending: **10**
- Management/operations combined for the requested summary: **11**
- Independent VAPT pending: **2**

The mutually exclusive primary ledger categories still total 51 controls.

## 12. Production recommendation

**READY FOR NEXT SECURITY VALIDATION STAGE — NOT PRODUCTION READY.**

The next manual stage requires actual release devices/emulators, safe dummy accounts, approved staging authorization, a company-signed mobile build and real authorized reviewers. P-46/P-47 independent VAPT/retest remain open.

