# P-06 Private Media Verification Checklist

Test only synthetic users/files in staging. Do not capture customer media, storage credentials, signed query strings, or raw identity documents.

## CODE VERIFIED

- Protected profile delivery uses `/api/media/profile/:userId/:filename`; unrestricted `/uploads` static delivery is absent.
- Chat and identity media use authenticated owner/participant or permission checks.
- Basename/path membership, MIME signature/type, file-size and randomized filename controls exist.
- Blocked, deactivated and deleted-user visibility rules are enforced in repository paths.

## LOCAL RUNTIME VERIFIED

Phase 3 tests passed anonymous, owner, other-user, blocked/deactivated, invalid-owner and traversal cases. Evidence: `evidence/tests/database/phase3-control-validation.md` and backend full-suite evidence.

## STAGING VERIFICATION REQUIRED

- [ ] Anonymous protected-media URL returns 401/403 and never file bytes — `P06_01_anonymous_media_denied.png`.
- [ ] Authorized owner/visible user receives only the expected file with private/no-store headers — `P06_02_authorized_media_access.png`.
- [ ] User A cannot fetch protected User B media outside approved visibility — `P06_03_cross_user_media_denied.png`.
- [ ] Blocked user media is inaccessible where required — `P06_04_blocked_media_denied.png`.
- [ ] Deactivated/deleted profile media is not public/discoverable — `P06_05_inactive_media_absent.png`.
- [ ] Traversal and alternate-encoding attempts fail — `P06_06_traversal_denied.txt`.
- [ ] Chat participant and identity admin-role boundaries pass — `P06_07_chat_identity_authorization.md`.
- [ ] If signed delivery is deployed, expired/replayed URL fails — `P06_08_expired_signed_url_denied.png`.

## INFRASTRUCTURE EVIDENCE REQUIRED

- [ ] Direct bucket/mount/CDN object URL is not public — `P06_09_direct_storage_anonymous_denied.txt`.
- [ ] Sanitized bucket/ACL/IAM policy shows least privilege — `P06_10_storage_access_policy_redacted.json`.
- [ ] At-rest encryption/key reference is captured — `P06_11_storage_encryption_redacted.png`.
- [ ] Lifecycle/deletion of a synthetic object is demonstrated — `P06_12_storage_lifecycle_delete.md`.

Pass only when every applicable staging and infrastructure item has real evidence. Current status: **IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED**.
