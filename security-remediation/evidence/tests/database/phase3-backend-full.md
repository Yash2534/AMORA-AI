# Phase 3 Full Backend Runtime Evidence

- Date: 2026-10-09.
- Working directory: `D:\Projects\amora_ai\Backend`.
- Command: `npm test` (`node --test --test-concurrency=1`).
- Environment: `NODE_ENV=test`; isolated local test-prefixed MariaDB schemas; dummy secrets/accounts only.
- Production accessed: **NO**.

## Attempts and final result

- Initial complete attempt: 346 tests; 333 passed, 13 failed. Failures were classified as stale fixtures for new MFA/legal/media behavior plus one serializer defect. They were not hidden or weakened.
- Focused post-fix suite: 52 passed, 0 failed.
- Final complete run: **347 passed, 0 failed, 0 skipped, 0 blocked**, exit code 0, duration 232,684 ms.
- Final protected-path/test-database guard unit rerun after adding invalid-owner regression: **13 passed, 0 failed**, exit code 0.

Security defects corrected during validation:

- Shared OTP rate-limit state incorrectly blocked legitimate request-to-verification/reset progression. Request, verification, and reset buckets are now separate while remaining throttled.
- Notification and event serializers omitted the owner ID when generating protected-media URLs; this could yield null or `NaN` paths. Owner-bound URLs and invalid-user-ID rejection are now enforced.

Test corrections updated stale assumptions without weakening controls: MFA-protected admin tests now perform real enrollment and step-up; legal-document fixtures retire/restore seeded active versions; protected-media expectations use authenticated routes; the permission-catalog count includes the two grievance permissions.

Relevant passing areas include refresh/password session revocation, deactivation/reactivation, account deletion rollback, privacy export ownership/expiry/deletion, consent history, admin RBAC/MFA/audit, location minimization, media authorization, age mutation paths, transaction rollback, and route authorization/error boundaries.
