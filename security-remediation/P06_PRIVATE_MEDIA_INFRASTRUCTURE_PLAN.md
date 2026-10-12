# P-06 Private Media Infrastructure Plan

Current status: **IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED**.

Repository evidence supports authenticated profile-media delivery and randomized private identity/chat storage paths. It does not prove deployed bucket/mount privacy, encryption, IAM, logging or lifecycle behavior.

## Required staging proof

- Inventory profile, identity-verification and chat media storage/CDN paths.
- Prove public access block and no unrestricted bucket/object/container policy.
- Anonymous request to a known dummy object is denied; authenticated authorized owner/participant access succeeds.
- Cross-user, blocked-pair and deactivated-user requests are denied according to policy.
- If signed URLs are used, record maximum expiry and show expired/replayed URL denial; never retain a live URL in evidence.
- Show server-side encryption/KMS reference, least-privilege workload IAM and access logs.
- Delete/replace a dummy object and verify application record, origin object, CDN/cache and lifecycle behavior.
- Verify logs contain no object contents, bearer credentials or unnecessary personal data.

Evidence: sanitized ACL/IAM/public-access/encryption/lifecycle exports; negative/positive result metadata; access-log event references; deletion/cache result; owner/reviewer/date. Do not mark complete without real storage proof.
