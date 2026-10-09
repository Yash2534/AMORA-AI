# Blocked External, Legal, Management, and Independent Validation Items

These controls are intentionally not marked complete. Evidence must identify the exact release commit/build and be retained in the controlled release evidence store.

| ID | Blocker | Owner | Required proof / next action |
|---|---|---|---|
| P-03 | TLS termination is outside source | DevOps | Sanitized edge config; TLS protocol/cipher scan; HTTP redirect, HSTS and WSS result; certificate owner/renewal alert; release-device capture |
| P-04 | Provider encryption and DB network path | Infrastructure + DB | Encrypted service/volume/snapshot setting; KMS/key-access record; CA/hostname-verified DB TLS result; fail-closed test |
| P-05 | No real backup/restore execution | DevOps + DB | Approved RPO/RTO; encrypted schedule; separate backup identity; isolated restore report with date, duration, checks, corrective actions |
| P-06 | Production object/mount controls | Infrastructure | Private bucket/mount ACL; encryption/KMS setting; app identity policy; public-access negative check; deletion/lifecycle evidence |
| P-08 | Managed key lifecycle | Infrastructure + Security | KMS inventory, owners, IAM, rotation/recovery drill, access audit and alert sample |
| P-09/P-42 | Company signing key and binaries absent | Management + Mobile + Release | Company custody record; protected injection; signed APK/IPA; signature verification; manifest/entitlement and redacted binary secret scan |
| P-12 | CERT-In applicability/retention/location | Legal + Security + DevOps | Dated counsel/security interpretation and deployed sink region/retention/access/immutability/time-sync evidence |
| P-15 | Incident reporting legal workflow | Legal + Security | Current authoritative source register; applicable incident types; trigger/clock/approver/reporter/contact; rehearsal record |
| P-17 | Final policies/Terms | Legal + Product | Approved legal entity/contact, accurate data-flow disclosures, signed approval, stable published URL and store linkage |
| P-21 | Retention schedule | Legal + Privacy | Field/category decisions, basis, duration/trigger, exception, deletion/anonymization action, approver and effective date |
| P-23 | Processor contracts | Legal + Procurement + Security | Executed DPA/contract, region/transfer terms, security review, subprocessor and deletion/incident obligations for each vendor |
| P-27 | Liveness/vendor governance | Product + Privacy + Legal | Necessity assessment, approved vendor, liveness test evidence if claimed, DPA, retention/deletion configuration, staff-access review |
| P-28 | Platform attestation | Mobile + Security | Play Integrity/Apple equivalent decision, privacy review, server verification, replay/invalid result tests, monitoring/appeal procedure |
| P-29 | Human moderation | Safety + Operations | Named staffed queue, training, coverage calendar, SLA/escalation, sampled case evidence and appeal process |
| P-30 | Anti-scam operation | Safety + Product | Approved taxonomy/rules, staffed escalation, repeat-offender workflow, user guidance, false-positive/appeal measures |
| P-33 | Distributed enforcement | DevOps + Backend | Shared-store attachment/config, multi-instance deterministic 429 test, proxy-hop topology, alert delivery and recovery test |
| P-38 | Company account ownership | Management + IT/Security | Signed register for Git/cloud/DNS/DB/stores/analytics/vendors; named identities, MFA/recovery, least privilege, offboarding and recertification |
| P-40 | DB exposure and identity | Infrastructure + DB | Private endpoint/firewall evidence, approved negative public connection test, TLS, least-privilege grants, separate app/backup identities |
| P-41 | Store readiness | Product + Legal + Release | Organization account proof; current forms; privacy/deletion URLs; rating/UGC/permission declarations; reviewer access record |
| P-43 | Hosted branch protection | Repository administrators | Default/release branch rules export: reviews, status checks, conversation resolution, restricted force-push/deletion, signed/bypass policy |
| P-44 | Real deployment gate | Release + DevOps | Protected environment, least-privilege deploy identity, required approver, immutable artifact binding, changelog and dated staging rollback drill |
| P-45 | Production monitoring/on-call | SRE + Security | Dashboard and alert rules for auth/admin/export/API/storage/outage; delivery tests; on-call schedule; runbook links; false-positive review |
| P-46 | Independent VAPT absent | Security + Management | Written authorization and scope; qualified independent provider report matching release candidate across mobile/API/admin/cloud/DB/storage/auth/business logic |
| P-47 | Independent retest absent | Security + Engineering + Management | Finding register, owners/dates, Critical closure, High fix or authorized risk decision, provider retest and residual-risk approval |
| P-49 | Named owners absent | Management | Primary/backup names and reachable channels for commander/security/backend/infra/product/ops/legal/comms/support/approver; 24x7 contact test |
| P-50 | Current legal verification absent | Legal + Support + Security | Counsel-approved source/effective-date/trigger/deadline register and notice templates. The May 13 2027, 72-hour, ₹250 crore, and CERT-In interpretation claims remain pending |
| P-51 | No real exercise | Security + Legal + Operations | Dated participant/timeline/decision/communications/action record for each scenario; closure evidence for material actions |

## Independent VAPT scope request (P-46/P-47)

The authorization should name Android/iOS builds, API/admin origins, cloud/IAM, DB/storage, OTP/session, BOLA/IDOR, injection, throttling, uploads/media, privacy exports, moderation and business logic. It must prohibit production-data access unless separately authorized, define test windows and emergency contacts, and require a signed report plus independent retest. Repository review is not a VAPT certificate.
