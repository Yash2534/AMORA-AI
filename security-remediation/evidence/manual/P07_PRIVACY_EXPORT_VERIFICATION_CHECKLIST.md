# P-07 Privacy Export Verification Checklist

Use dummy users A/B. Never attach raw export contents; record field names, hashes, sizes and redacted screenshots only.

## LOCAL CODE/RUNTIME PASS

- Canonical API: authenticated `/api/privacy-requests/:id/export` and `/export/download`; legacy `/api/(v1/)privacy/data-export` returns 410.
- Owner predicates prevent cross-user generation/download.
- Password step-up and one-time confirmation are required by the request lifecycle.
- Field scope is allowlisted in `privacyExportArtifactService`; raw passwords/tokens/OTP/internal coordinate fields are excluded.
- Local artifact storage is private, expiry is bounded, download consumes/deletes, and failed generation cleans up.
- Phase 3 privacy tests passed ownership, expiry, one-time deletion and failure cleanup.

## STAGING / PRODUCT VERIFICATION REQUIRED

- [ ] A creates/verifies an EXPORT request — `P07_01_owner_export_request.png`.
- [ ] A cannot generate/download B's request — `P07_02_cross_user_denied.png`.
- [ ] Unauthenticated generation/download fails — `P07_03_unauthenticated_denied.png`.
- [ ] Approved field manifest matches product/privacy decision — `P07_04_approved_field_manifest.md`.
- [ ] Expired artifact returns denial — `P07_05_expired_artifact_denied.png`.
- [ ] Downloaded/consumed artifact is unavailable and removed — `P07_06_consumed_artifact_deleted.md`.
- [ ] Application/security logs contain metadata only, not export data — `P07_07_log_content_redacted.txt`.

## REAL STORAGE/INFRASTRUCTURE PROOF REQUIRED

- [ ] Deployed artifact location is private and direct anonymous access fails — `P07_08_private_storage_denial.txt`.
- [ ] Encryption/KMS and app identity policy are exported redacted — `P07_09_encryption_iam_redacted.json`.
- [ ] Expiry/deletion job or object lifecycle is evidenced — `P07_10_deployed_expiry_delete.md`.

Current status: **IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED**. Field/retention approval remains a Product/Privacy/legal dependency.
