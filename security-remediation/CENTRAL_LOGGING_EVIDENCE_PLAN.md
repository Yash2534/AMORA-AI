# Central Logging Evidence Plan

Primary control: P-39. P-12 legal retention/location and P-14 repository redaction are related but remain separate controls.

## Required evidence

- Centralized sink/resource and every workload/source connected to it.
- Least-privilege human/workload access; application/admin identities cannot alter or delete retained audit records.
- Provider immutability/tamper-resistance or append-only controls and a prohibited-mutation result.
- Legal-approved retention and location; no duration is selected by this plan.
- UTC/clock synchronization and timestamp-skew monitoring.
- Redaction sampling covering passwords, OTPs, tokens, cookies, keys, identity documents and personal-data payloads.
- Ingestion of login/security, administrator/privilege, moderation, privacy-export and audit-integrity events.
- Integrity-chain verification result and alert integration/delivery.

Pass requires sanitized configuration/grants, source-to-sink samples using dummy events, denied mutation, retention/location approval reference, clock proof, redaction review and delivered alert evidence. Local audit rows/hash chains do not by themselves prove a centralized immutable sink.
