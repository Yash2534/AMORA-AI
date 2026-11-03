# AMORAA S3 private object-storage validation

Date: 2026-10-12

Status: **BLOCKED — IMPLEMENTATION AND INFRASTRUCTURE REQUIRED**

Applies to profile photos, chat media, identity-verification media and privacy exports, and overlaps security controls P-06/P-07.

## Required architecture

Private-by-default storage with public access blocked; encryption at rest using approved keys; workload identity rather than static credentials; separate prefixes/buckets and IAM per data class; random non-semantic object keys stored in MySQL; content-type/signature/size validation; metadata stripping and scanning/derivatives where required; access logs; version/lifecycle policy; and retryable deletion workflow.

Profile access policy must be explicit. Chat/verification/export objects require authenticated authorization or short-lived, audience-scoped signed access. Signed URLs must expire, be unguessable and not be logged with query signatures. Privacy exports retain their repository owner/status/expiry semantics and must be deleted after consumption/expiry with auditable retries.

## Validation

Upload through API A, read through B, replace and delete, then terminate A to prove no local dependency. Test anonymous denial, wrong-user denial, signed expiry, MIME/signature mismatch, oversize upload, metadata handling, encryption/IAM evidence, access logging, lifecycle expiry, storage outage and retry cleanup. Verify no object becomes public and no raw identity/media metadata enters logs.

## Migration requirement

Do not dual-write or migrate existing local files without a separately reviewed plan. A safe rollout needs an object-storage abstraction, database object state/key, checksum, idempotent copy, read fallback during migration, reconciliation and rollback. No cloud configuration or data migration was authorized in S3.

