# Central Logging Evidence

- Acceptable: sink/IAM/retention/time-sync exports, dummy event ingestion, redaction sample, prohibited-mutation result, integrity result and alert delivery.
- Unacceptable: local console logs, raw PII/secrets, source event code alone or a retention duration lacking Legal approval.
- Redact: tokens, credentials, personal data, contact data and unrelated tenants; retain event family, timestamp, actor alias, outcome and sink reference.
- Provider: Security/DevOps/Logging owners; Legal approves retention/location.
- Pass: required events reach a restricted tamper-resistant sink, clocks align, sensitive fields are absent, retention is approved and alerts deliver.
