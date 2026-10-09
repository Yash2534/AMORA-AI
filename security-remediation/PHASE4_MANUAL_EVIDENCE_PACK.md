# Phase 4 Manual Evidence Pack

No manual, staging, infrastructure, product, legal or management evidence was collected. This pack defines exactly what a real reviewer must do using synthetic data. Production access is not authorized.

## P-06

CONTROL: Private protected media.  
Already implemented: authenticated profile/chat/identity delivery, ownership/visibility/block/inactive checks, traversal/type/size controls.  
Already runtime tested: anonymous/owner/cross-user/blocked/deactivated/traversal cases in Phase 3.  
What is proven: local API authorization and file controls.  
What is NOT proven: deployed object privacy, encryption/IAM, signed URL expiry, lifecycle.  
Who/where: Backend + Infrastructure/Security in staging storage/CDN.  
Exact steps/evidence: run `P06_MEDIA_VERIFICATION_CHECKLIST.md`; screenshots and policy/log exports required.  
Pass/fail: pass only if all protected paths deny unauthorized/direct access and storage policy is private/least privilege.  
Can be marked COMPLETE after evidence: YES, after Product/Privacy accepts visibility rules and infrastructure evidence passes.  
Other dependency: storage/KMS evidence.

## P-07

CONTROL: Privacy export security.  
Already implemented: canonical authenticated owner-scoped, step-up, allowlisted private artifact with expiry/consume/delete.  
Already runtime tested: cross-user, expiry, deletion and failure cleanup.  
What is proven: local code/lifecycle.  
What is NOT proven: deployed private encrypted storage/KMS and approved fields/retention.  
Who/where: Backend/Privacy plus Infrastructure in staging; Legal/Product for field/retention approval.  
Exact steps/evidence: `P07_PRIVACY_EXPORT_VERIFICATION_CHECKLIST.md`; redacted screenshots/logs/policies required.  
Pass/fail: fail on cross-user access, raw content in logs, public object, stale artifact, unapproved field.  
Can be marked COMPLETE after evidence: YES, when infrastructure and approvals exist.  
Other dependency: legal retention decision.

## P-16

CONTROL: Data minimization and mobile permissions.  
Already implemented: contextual typed permission service, Android system photo-picker path, no background location/broad storage, iOS usage descriptions.  
Already runtime tested: Flutter permission tests and manifest assertions.  
What is proven: source declarations/timing abstractions/denial handling.  
What is NOT proven: merged signed artifacts and real-device denied/limited/one-time behavior; necessity of Android `READ_MEDIA_IMAGES`/fine location.  
Who/where: Mobile + Product + Privacy on Android/iOS staging release builds.  
Exact steps/evidence: `PERMISSION_PURPOSE_MATRIX.md`; files named in `evidence/manual/P-16/EVIDENCE_MANIFEST.md`.  
Pass/fail: fail on startup prompts, unused/broad permission, bypass after denial, or mismatch with approved purpose.  
Can be marked COMPLETE after evidence: YES, after product/privacy approval and device captures.  
Other dependency: signed release artifact under P-42.

## P-22

CONTROL: Data-principal request lifecycle.  
Already implemented: canonical owner-scoped request/status/step-up/access/export/correction/withdrawal services.  
Already runtime tested: owner/cross-user/status/export lifecycle.  
What is proven: repository ownership and local lifecycle.  
What is NOT proven: operational queue, notification, approved deadline/SLA, end-user staging journey.  
Who/where: Privacy Operations/Product in staging; Legal for deadlines.  
Exact steps/evidence: `P22_RIGHTS_REQUEST_E2E.md`; sanitized captures/log exports required.  
Pass/fail: fail on enumeration/cross-user access, invalid transition, stale export, or personal data in errors/logs.  
Can be marked COMPLETE after evidence: NO until legal deadline/workflow approval is also supplied.  
Other dependency: Legal SLA and P-19 retention/deletion rules.

## P-25

CONTROL: Server-side 18+ enforcement.  
Already implemented/runtime tested: shared UTC age policy, exact 18/underage/future/invalid/mutation/discovery tests.  
What is proven: server cannot be bypassed by direct API mutation.  
What is NOT proven: real Android/iOS UI journey and approved underage response policy.  
Who/where: Mobile/Product in staging; Legal/Product for policy.  
Exact steps/evidence: `P25_AGE_GATE_MANUAL_TEST.md`; screenshots/video/API response required.  
Pass/fail: fail if any client flow permits underage activation/discovery or hides server denial.  
Can be marked COMPLETE after evidence: NO until underage lifecycle policy is approved.  
Other dependency: Product/Legal policy.

## P-31

CONTROL: Location privacy.  
Already implemented/runtime tested: public serializers omit coordinates, distance quantized, blocked/inactive/deleted excluded.  
What is proven: local API paths.  
What is NOT proven: complete staging UI/deep-link/log/export review, product approval, triangulation assessment, incognito decision.  
Who/where: Backend/Product/Privacy/Security in staging and release devices.  
Exact steps/evidence: `P31_LOCATION_PRIVACY_VERIFICATION.md`; redacted JSON/screenshots/log scan required.  
Pass/fail: fail on coordinate leakage, unapproved precision, excluded user visibility, or triangulation risk without decision.  
Can be marked COMPLETE after evidence: YES after product/privacy sign-off and testing.  
Other dependency: incognito requirement decision (do not invent behavior).

## P-36

CONTROL: Route-wide API hardening.  
Already implemented/runtime tested: route matrix, auth/authorization/validation/ownership/error/CORS/payload controls; 347-test Phase 3 suite passed.  
What is proven: 305 concrete route patterns; 279 protected/credential-bound, 26 intentionally public, 0 known active high-risk auth gaps.  
What is NOT proven: staging edge/proxy/header/error behavior and release-commit human sign-off.  
Who/where: Backend/Security/DevOps in staging.  
Exact steps/evidence: `API_SECURITY_COVERAGE_FINAL.md` and P-36 manifest; JSON/header captures required.  
Pass/fail: fail on unauthenticated/cross-user access, unsanitized 5xx, permissive CORS, missing security headers or payload bypass.  
Can be marked COMPLETE after evidence: YES after staging capture/sign-off.  
Other dependency: P-03/P-33/P-40 topology evidence remains separate.

## P-37

CONTROL: Admin hardening.  
Already implemented/runtime tested: no default seed, admin session/RBAC/MFA/fresh step-up/audit and destructive paths; Phase 3 admin/full suite passed.  
What is proven: repository route protections and audit behavior.  
What is NOT proven: real admin roster/company ownership, operational approvals and staging session behavior.  
Who/where: Security/Admin owner/Management in staging and controlled access register.  
Exact steps/evidence: `P37_ADMIN_MANUAL_VERIFICATION.md`; sanitized screenshots/audit JSON/roster export required.  
Pass/fail: fail on wrong-role success, missing MFA/step-up, unaudited sensitive action/read, shared/default account or excessive role.  
Can be marked COMPLETE after evidence: YES for P-37 when manual/management evidence passes; P-38 remains separate.  
Other dependency: management decision on two-person approval where desired.
