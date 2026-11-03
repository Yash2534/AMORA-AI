# Staging Access Required

Status: **BLOCKED — STAGING ACCESS REQUIRED**

No staging hostname was explicitly approved in Phase 7. No arbitrary public URL was probed.

## Required authorization

- Exact hostname: `https://<approved-staging-hostname>`
- Written owner authorization and test window
- Release/build/commit identifier
- Confirmation that the environment is isolated from production data and providers unless test-mode providers are explicitly approved
- Allowed source IP/device and rate-limit test ceiling
- Evidence retention/redaction owner
- Rollback/contact for unexpected impact

## Required dummy principals

- User A: complete active profile with synthetic location/media
- User B: separate owner for cross-user denial
- Blocked user and blocker pair
- Deactivated user
- Disposable user approved for erasure
- Normal non-admin user
- Lower-privilege admin
- Authorized admin with test MFA and fresh-step-up capability
- No default/shared account; no production identity

## Required data and services

- Synthetic media/export artifacts only
- Coarse and exact internal test coordinates whose public exposure can be assessed safely
- Private logging view with redaction authorization
- Test email/SMS delivery or explicit delivery suppression approved for staging
- Shared rate-limit/proxy topology information for non-destructive checks
- Operational privacy-request queue owner

## Required evidence

- P-11: release traffic capture, endpoint/build ID, secure-storage lifecycle screenshots/logs
- P-22: sanitized request/status/cross-user/expiry/deletion evidence
- P-31: `P31_location_api_redacted.json` plus UI/log/export review and Product/Privacy decision
- P-36: `P36_cors_https_headers.txt`, sanitized auth/ownership/invalid-ID/error/rate-limit results
- P-37: role/MFA/session/audit captures and approved role roster
- P-26: provider delivery plus signed Product/Security/Support decision

Approval must explicitly exclude production and authorize only the named staging host and dummy identities.

