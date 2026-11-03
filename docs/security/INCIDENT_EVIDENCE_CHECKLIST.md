# Incident evidence checklist

- Incident ID, UTC timeline, reporter, and evidence custodian
- Affected services, versions, commit/deployment identifiers, and environment
- Sanitized authentication, authorization, admin-audit, WAF/proxy, database, and provider logs
- Relevant configuration snapshots with secret values redacted
- Indicators of compromise and file hashes
- Account/session impact and credential-rotation record (references only, no secret values)
- Data categories, approximate record scope, and affected jurisdictions if verified
- Containment and recovery actions with approver and timestamp
- Backup/restore validation evidence when used
- Third-party notices, case numbers, and vendor evidence
- Chain-of-custody entries for exported evidence
- Root cause, corrective actions, validation results, and residual risks

Store evidence in an access-controlled, retention-approved location. Do not commit operational evidence or personal data to this repository.

