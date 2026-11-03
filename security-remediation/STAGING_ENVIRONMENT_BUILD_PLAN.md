# Staging Environment Build Plan

Status: **BLOCKED — DEVOPS / MANAGEMENT STAGING APPROVAL REQUIRED**

No hostname is assumed or authorized. Suggested names are `api-staging.<company-domain>` and `admin-staging.<company-domain>` only.

## Required architecture

- A separately authorized staging hostname and DNS zone/records.
- Separate staging API, admin surface, database, private media/export storage, credentials and workload identities.
- Dummy test data only; no production customer data, database copy, admin, credentials, keys or private signing material.
- HTTPS only; WSS where the realtime/socket path is enabled; HTTP must redirect or be rejected.
- Staging-specific restrictive CORS origins and trusted-proxy settings.
- Separate centralized logs, monitoring, alert destinations and distributed rate-limit store.
- Staging-only SMS/email/provider configuration with allowlisted synthetic destinations and spend limits.
- Separate Firebase project/config if push testing is required; classify public mobile identifiers separately from server credentials.
- Environment-labelled backups and restoration only to an isolated staging recovery target.

## Approval/build sequence

1. Management records the approved scope, company domain, owner, cost/budget, test window and explicit exclusions.
2. DevOps creates isolated network, API/admin workloads, DB, storage, KMS/secrets, logging, monitoring and shared rate-limit resources.
3. Security reviews IAM, ingress/egress, public exposure, CORS, proxy and redaction settings before data/accounts are created.
4. Database owner migrates an empty schema and creates separate least-privilege app and backup identities.
5. Mobile/Release injects the approved staging API URL and staging provider configuration into a non-production build.
6. Operations provisions only the identities in `STAGING_TEST_ACCOUNT_REQUIREMENTS.md` and `DUMMY_ADMIN_SETUP_PLAN.md`.
7. DevOps records sanitized resource IDs/config exports and runs the evidence templates. Secrets and tokens are never captured.
8. Security signs the staging authorization record before Phase 9 traffic, account or device testing begins.

## Exit criteria

Approved hostname and window; documented owner; isolated API/admin/DB/storage/credentials; dummy identities; HTTPS/WSS; staging CORS/proxy; logs/monitoring/rate limiting; provider isolation; rollback/cleanup owner; and an explicit `Production accessed: NO` record. Until all exist, Phase 9 remains blocked.
