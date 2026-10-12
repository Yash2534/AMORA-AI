# KMS and Secrets Evidence

- Acceptable: sanitized key/secret inventory references, IAM/workload policies, environment isolation, access logs, rotation event and recovery/break-glass drill.
- Unacceptable: secret values, screenshots revealing values, repository env-variable names alone, or an untested rotation policy.
- Redact: every value/version payload, private key, token, account number and recovery factor; retain identifiers, roles, dates and actions needed for audit.
- Provider: Security/DevOps/KMS owners; signing custody evidence may also require Release.
- Pass: managed storage, separation, least privilege, auditing, current rotation and tested recovery for every active secret category.
