# Incident response plan

Status: operational template. Named owners, counsel-approved notification duties, and tested contact channels remain TODO.

## Lifecycle

1. Detect and open an incident record with UTC timestamps and a restricted evidence location.
2. Triage scope, affected systems/data, confidence, active exploitation, and safety impact.
3. Contain using reversible measures where possible; preserve evidence before destructive cleanup.
4. Eradicate the cause, rotate affected credentials through the authorized external process, and validate clean state.
5. Recover in stages with monitoring and an explicit rollback decision.
6. Complete lessons learned, corrective actions, and evidence retention decisions.

## Guardrails

- Do not access or copy more personal data than required for response.
- Never place secrets, OTPs, tokens, raw identity numbers, or customer exports in tickets or chat.
- Legal/regulatory notification timing and recipients require current counsel verification; this document states no deadline.
- Public communications require management and legal approval.
- Independent forensics/VAPT results must be attached as external evidence, never inferred from repository tests.

## Required roles

Incident commander, technical lead, evidence custodian, communications lead, privacy/legal liaison, service owner, and executive approver. Assign real people and backups in the restricted operational register.

