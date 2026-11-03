# P-07 Privacy Export Infrastructure Plan

Current status: **IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED**.

Local implementation uses owner-scoped records, random storage keys, restricted local file mode, an expiry of at most 24 hours, deletion after download and expired-artifact cleanup. Deployed private storage, KMS, IAM, cleanup scheduling and access logging remain unverified.

## Required staging proof

- Private export store with public access disabled and no direct anonymous object access.
- Encryption at rest with approved KMS/key ownership and TLS in transit.
- Workload identity can create/read/delete only the required prefix; human access is restricted/audited.
- USER-B cannot discover or download PRIVACY-REQUEST-USER's export; authorized download succeeds only through the application.
- Expired and consumed dummy artifacts return the expected denial and are deleted from origin/cache/metadata according to policy.
- Cleanup job/scheduler execution and failure alert are evidenced.
- Access logs contain resource metadata only and no export content, token, direct live URL or unnecessary personal data.

Retain sanitized configuration exports, authorization/expiry/delete results, job/log references and reviewer/date. Legal approval of fields/retention remains separate.
