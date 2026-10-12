# Secrets and KMS Evidence Plan

Controls: P-08 and P-10. Status remains infrastructure-evidence pending.

## Secret categories

- DB credentials and separate backup credentials
- JWT access, refresh/session and admin signing secrets
- OTP/SMS and email provider secrets
- Firebase/server provider credentials
- Administrator MFA encryption key
- Media/export storage credentials and encryption keys
- Android/iOS release-signing credentials and signing-service authorization
- Payment, AI and other third-party API secrets

## Required proof

For each category record only a sanitized secret ID/reference, owner, environment, consumer workload, IAM role, creation/last-rotation/next-rotation dates and recovery method. Show managed KMS/secrets-manager use; dev/stage/prod separation; least-privilege workload access; denied unauthorized access; audit logging; rotation without unsafe downtime; recovery/break-glass test; and no secret in repository, build output or ordinary logs.

Run hosted and local repository/history/artifact scans with redacted output. Every finding needs disposition and rotation reference where exposure cannot be excluded. Never paste values, private keys, credentials, tokens or recoverable ciphertext. Screenshots must redact values, version payloads, session identifiers, account numbers and unrelated resources.

Pass only when all active secret categories are inventoried, managed, isolated, least-privilege, audited and covered by current rotation/recovery evidence. Repository environment-variable consumption alone is insufficient.
