# Manual Verification Register

All rows are **UNVERIFIED**. `Verified by`, `Verification date`, and evidence references must be completed by a real reviewer. Screenshots/exports must be sanitized. Phase 2 collected local Flutter and source-scan evidence only; it did not supply any human, device, console, infrastructure, legal, management, or VAPT evidence, so no manual row was changed to verified.

| Control | Manual check | Reviewer / location | Required evidence | Pass / fail criteria | Status | Verification record |
|---|---|---|---|---|---|---|
| P-03 | TLS 1.2+, HTTPS/WSS, redirect, HSTS, certificate renewal | DevOps/Security; edge/CDN/load balancer and staging device | Edge export, TLS scan, HTTP redirect/HSTS capture, WSS result, renewal alert | Pass only if obsolete protocols/plaintext are rejected and certificate ownership/renewal is proven | UNVERIFIED | By: TBD; Date: TBD; `evidence/infrastructure/P-03/` |
| P-04 | DB at-rest encryption and CA/hostname-verified TLS | DB/Infrastructure; provider console and staging runtime | Encryption/KMS export, TLS-required connection result, encrypted snapshot proof | Fail if plaintext connection or unencrypted service/snapshot is permitted | UNVERIFIED | TBD; `evidence/infrastructure/P-04/` |
| P-05 | Backup encryption, isolated identity, RPO/RTO, restore | DB/DevOps; backup console and isolated restore environment | Schedule/policy export, identity grants, dated restore report and timings | Pass only after recoverable restore meets approved objectives | UNVERIFIED | TBD; `evidence/infrastructure/P-05/` |
| P-06 | Production media storage private/encrypted and lifecycle enforced | Infrastructure/Backend; bucket/mount/CDN | ACL/policy export, anonymous negative check, encryption and deletion evidence | Fail if protected object is public or app identity exceeds required access | UNVERIFIED | TBD; `evidence/infrastructure/P-06/` |
| P-08 | KMS/secrets-manager ownership, IAM, rotation/recovery | Infrastructure/Security; KMS and IAM consoles | Key inventory, role policy, access log, rotation/recovery drill | Pass only with separated keys, least privilege, audit and tested recovery | UNVERIFIED | TBD; `evidence/infrastructure/P-08/` |
| P-09 | Signed APK/IPA source/assets/binary secret scan | Mobile/Security; release artifacts and CI | Artifact hashes/signatures and redacted scanner reports for all variants | Fail on embedded server secret/private key or unexplained high-confidence finding | UNVERIFIED | TBD; `evidence/manual/P-09/` |
| P-10 | Managed secret storage, environment separation, history scan/rotation | DevOps/Security; secret manager, Git host, CI | Sanitized policy, scanner run, history disposition, rotation record references | Fail if production secrets reside in repo/ordinary CI variables or are shared across envs | UNVERIFIED | TBD; `evidence/manual/P-10/` |
| P-11 | Release traffic HTTPS and token storage/clear behavior | Mobile/Security; Android/iOS release devices and staging proxy | Traffic capture, secure-storage inspection, logout/delete/password-change test | Fail on HTTP release endpoint, ordinary-preferences token, or retained credential after lifecycle event | UNVERIFIED | TBD; `evidence/manual/P-11/` |
| P-12 | Log categories, region, retention, immutable access | Legal/Security/DevOps; counsel record and logging console | Counsel decision plus sink region/retention/access/time-sync export | Fail if legal applicability is assumed or configured retention/location differs | UNVERIFIED | TBD; `evidence/legal/P-12/`, `evidence/infrastructure/P-12/` |
| P-16 | Permission necessity and denial/limited behavior | Product/Mobile/Privacy; release devices | Permission-purpose map, screenshots, denied/limited tests | Fail on unused/broad permission or feature bypass of consent/context | UNVERIFIED | TBD; `evidence/manual/P-16/` |
| P-17 | Policy/Terms accuracy and stable publication | Legal/Product; approved docs, public URLs, stores | Signed versions, URL checks, data-flow comparison, store linkage | Fail on unapproved entity/contact, unsupported claim, or mismatch with behavior | UNVERIFIED | TBD; `evidence/legal/P-17/` |
| P-21 | Retention schedule and operational jobs | Legal/Privacy/Backend; schedule and staging data lifecycle | Signed schedule and job/deletion proof across DB/files/backups/vendors | Fail if any category lacks owner/trigger/action or approved exception | UNVERIFIED | TBD; `evidence/legal/P-21/` |
| P-23 | Vendor inventory and executed DPA/contract review | Legal/Procurement/Security; contract repository | Executed agreements, region/subprocessor/security/deletion/incident terms | Fail if any active processor lacks review and executed obligations | UNVERIFIED | TBD; `evidence/legal/P-23/` |
| P-27 | Identity necessity, storage access, retention, deletion, vendor/liveness | Product/Privacy/Legal/Security; admin UI, storage, vendor console | DPIA/necessity decision, access review, deletion test, DPA and liveness proof if claimed | Fail if raw IDs persist without approved need/limit or liveness is claimed without evidence | UNVERIFIED | TBD; `evidence/legal/P-27/`, `evidence/manual/P-27/` |
| P-28 | Platform attestation and false-positive/appeal process | Mobile/Backend/Security/Product; provider console/staging | Config, server verification/replay tests, monitoring and appeal procedure | Fail if client-only result is trusted or no replay/invalid handling exists | UNVERIFIED | TBD; `evidence/manual/P-28/` |
| P-29 | Moderation staffing, queue, SLA, escalation and appeal | Safety/Operations/Product; moderation system | Roster/schedule, training, SLA, sampled cases and appeal proof | Fail if queue is unstaffed or severe reports lack escalation | UNVERIFIED | TBD; `evidence/management/P-29/` |
| P-30 | Anti-scam taxonomy/rules/repeat-offender workflow | Safety/Product; moderation/analytics | Approved policy, sampled enforcement, metrics and false-positive review | Fail if repeat abuse is not linked/escalated or guidance/appeal absent | UNVERIFIED | TBD; `evidence/management/P-30/` |
| P-33 | Shared rate-limit store and trusted-proxy topology | DevOps/Backend; multi-instance staging/Redis | Store config, proxy diagram, deterministic cross-instance 429 and recovery evidence | Fail if limits are per-process or attacker-controlled headers determine identity | UNVERIFIED | TBD; `evidence/infrastructure/P-33/` |
| P-38 | Company ownership/access/MFA/offboarding register | Management/IT/Security; Git/cloud/DNS/DB/stores/vendors | Signed ownership export, named access, MFA/recovery and offboarding test | Fail on personal/shared owner account, missing MFA, stale access, or untested recovery | UNVERIFIED | TBD; `evidence/management/P-38/` |
| P-39 | Central audit sink, append-only role, retention, alerts | Security/Backend/DevOps; DB/logging/monitoring | Role grants, mutation-negative test, retention export, alert delivery and integrity report | Fail if app/admin can alter/delete audit rows or alerts do not deliver | UNVERIFIED | TBD; `evidence/infrastructure/P-39/` |
| P-40 | DB exposure/firewall/TLS/grants | DB/Infrastructure; cloud/DB console and approved negative vantage | Firewall/private endpoint export, public negative check, TLS and grants | Fail on public reachability or excessive/shared DB identities | UNVERIFIED | TBD; `evidence/infrastructure/P-40/` |
| P-41 | Google Play/Apple org status and declarations | Product/Legal/Release; store consoles | Org account proof, current Data Safety/App Privacy, URLs, age/UGC/permission forms, reviewer test | Fail on personal ownership or declaration/behavior mismatch | UNVERIFIED | TBD; `evidence/store/P-41/` |
| P-42 | Company signing, merged manifest/entitlements, release flags | Mobile/Release/Security; signing service and signed artifacts | Custody record, signature verification, merged manifest/entitlements, binary scan | Fail on debug signing/debuggable build/unintended export/backup | UNVERIFIED | TBD; `evidence/store/P-42/` |
| P-43 | Branch protection, required checks, SBOM and exceptions | Repo administrators/Security; Git hosting console/CI | Rules export, CI run URLs, SBOM, exception register | Fail if required checks/reviews can be bypassed without governed approval | UNVERIFIED | TBD; `evidence/manual/P-43/` |
| P-44 | Protected deployment environment, approver, identity, rollback | Release/DevOps; CI/CD and hosting console | Environment rules, deploy grants, release record, staging rollback drill | Fail on direct/unreviewed production push or untested rollback | UNVERIFIED | TBD; `evidence/infrastructure/P-44/` |
| P-45 | Monitoring dashboards, alert delivery and on-call | SRE/Security; monitoring and paging systems | Dashboard/rule exports, staging alert tests, on-call schedule and runbooks | Fail if any required signal lacks owner/delivery or outage coverage | UNVERIFIED | TBD; `evidence/infrastructure/P-45/` |
| P-46 | Independent VAPT scope/report authenticity | Security/Management; provider and secure evidence store | Authorization, scope/build ID and signed independent report | Fail if assessor is not independent or scope/build does not match release candidate | UNVERIFIED | TBD; `evidence/vapt/P-46/` |
| P-47 | Finding closure and independent retest | Security/Engineering/Management; finding register/provider | Owner/dates/fixes, risk decisions, signed retest and closure approval | Fail with open Critical or unapproved/uncompensated High | UNVERIFIED | TBD; `evidence/vapt/P-47/` |
| P-49 | Named incident owners and reachable escalation | Management; restricted contact/on-call register | Primary/backup roles, authority, contact test and review date | Fail on vacancies, unreachable contacts, or unclear containment/notification authority | UNVERIFIED | TBD; `evidence/management/P-49/` |
| P-50 | Counsel-approved breach/notification rule register | Legal/Security/Support; counsel record | Dated authoritative sources, triggers/clocks/approvers/templates and tabletop result | Fail if disputed claims are assumed or clock ownership is unclear | UNVERIFIED | TBD; `evidence/legal/P-50/` |
| P-51 | Completed real tabletop and action closure | Security/Legal/Operations; exercise record | Participants, timeline, decisions, communications, actions and closure proof | Fail if only a blank template exists or material actions remain open | UNVERIFIED | TBD; `evidence/drills/P-51/` |

## Phase 4 generated verification packs — evidence not yet collected

| Control | Generated pack | Current evidence state | Status |
|---|---|---|---|
| P-06 | `evidence/manual/P06_MEDIA_VERIFICATION_CHECKLIST.md`; `evidence/manual/P-06/` | Local runtime evidence exists; staging/storage screenshots and exports absent | UNVERIFIED |
| P-07 | `evidence/manual/P07_PRIVACY_EXPORT_VERIFICATION_CHECKLIST.md`; `evidence/manual/P-07/` | Local runtime evidence exists; deployed storage/KMS and approval evidence absent | UNVERIFIED |
| P-16 | `PERMISSION_PURPOSE_MATRIX.md`; `evidence/manual/P-16/` | Source/Flutter evidence exists; real-device/merged-artifact evidence absent | UNVERIFIED |
| P-22 | `evidence/manual/P22_RIGHTS_REQUEST_E2E.md`; `evidence/manual/P-22/` | Local runtime evidence exists; end-user/operations/legal evidence absent | UNVERIFIED |
| P-25 | `evidence/manual/P25_AGE_GATE_MANUAL_TEST.md`; `evidence/manual/P-25/` | Server evidence exists; Android/iOS journey and policy approval absent | UNVERIFIED |
| P-31 | `evidence/manual/P31_LOCATION_PRIVACY_VERIFICATION.md`; `evidence/manual/P-31/` | Local API evidence exists; staging/UI/triangulation/product evidence absent | UNVERIFIED |
| P-36 | `API_SECURITY_COVERAGE_FINAL.md`; `evidence/manual/P-36/` | Static and local runtime evidence exists; staging header/topology evidence absent | UNVERIFIED |
| P-37 | `evidence/manual/P37_ADMIN_MANUAL_VERIFICATION.md`; `evidence/manual/P-37/` | Local RBAC/MFA/audit evidence exists; roster/staging/management evidence absent | UNVERIFIED |

Phase 4 did not fill reviewer names, dates, screenshots, console exports or sign-offs. Every row remains pending until a human supplies genuine sanitized evidence.

## Phase 5 P-20/P-26 reconciliation — evidence not yet collected

| Control | Required real-world verification | Required evidence | Current state | Status |
|---|---|---|---|---|
| P-20 | Exercise local-password and Google-provider deactivation/reactivation on staging release clients using a real configured provider; confirm revoked sessions/devices remain rejected and notifications/discovery behavior matches policy | Sanitized staging run, build/config identifier, provider verification result, session/device negative checks, reviewer/date | Repository tests cover both authentication classes; no real-provider or release-device evidence was supplied | UNVERIFIED — SECONDARY RELEASE EVIDENCE |
| P-26 | Product/Security/Support approve normalization, reassignment, lost-number, recycled-number, recovery, dispute, escalation and evidence-handling rules; validate OTP delivery with the configured SMS provider in staging | Signed policy/version, named operational owner, sampled support procedure, redacted staging OTP delivery/expiry/replay evidence, reviewer/date | Technical lifecycle and concurrency boundary pass locally; policy approval and provider evidence are absent | UNVERIFIED — OPERATIONS/POLICY SIGNOFF REQUIRED |

No human reviewer, provider screenshot, policy approval, or operational sign-off was supplied in Phase 5. P-26 must not be represented as fully complete until these records exist.

## Phase 6 manual-evidence execution attempt — 2026-10-09

Manual-primary controls identified from the current ledger: **P-09, P-16, P-22, P-25 and P-37**. P-09 is the fifth item requested by Phase 6.

| Control | Phase 6 evidence collected | Result | Status |
|---|---|---|---|
| P-09 | Pre-existing Android APK hash; `apksigner` result; redacted scan of 795 APK entries | 0 high-confidence secret-pattern matches, but APK is Android Debug-signed; no company-signed APK/AAB or IPA | UNVERIFIED — MANUAL EVIDENCE REQUIRED |
| P-16 | ADB/device/AVD/Flutter inventory; explicit no-device record | No Android/iOS test device or AVD; no screenshots or Product/Privacy approval | UNVERIFIED — MANUAL EVIDENCE REQUIRED |
| P-22 | Checklist and prerequisite inventory | No device/staging/dummy UI credentials, operations queue evidence or legal SLA approval | UNVERIFIED — MANUAL EVIDENCE REQUIRED |
| P-25 | Checklist and prerequisite inventory | No Android/iOS device or AVD; no UI captures or underage-policy approval | UNVERIFIED — MANUAL EVIDENCE REQUIRED |
| P-37 | Checklist and prerequisite inventory | No staging/admin UI, dummy admin credentials, MFA device, roster or owner approval | UNVERIFIED — MANUAL EVIDENCE REQUIRED |
| P-26 | Unsigned Product/Security/Support signoff sheet | All approvers TBD/NOT SIGNED; SMS-provider staging evidence absent | UNVERIFIED — OPERATIONS/POLICY SIGNOFF REQUIRED |

Evidence records are under `evidence/manual/P-09/`, `P-16/`, `P-22/`, `P-25/`, `P-37/` and `P-26/`. No manual control changed to COMPLETE. Existing automated tests are not substituted for the missing human/device/staging evidence.

## Phase 7 environment reconciliation — 2026-10-09

The Android SDK/emulator toolchain is installed, but no system image, AVD, connected Android/iOS device, company-signed artifact, approved staging host, dummy admin/MFA identity or real approver is available. The local seed tooling is not treated as a currently approved/tested account environment. Accordingly:

- P-09/P-16/P-22/P-25/P-37 remain unverified;
- P-11/P-31/P-36 remain staging-evidence pending;
- P-26 remains unsigned;
- no screenshot, API response, role result or approval was added as a pass.

Exact setup and human execution requirements are in `PHASE7_VALIDATION_ENVIRONMENT_DISCOVERY.md`, `ANDROID_MANUAL_TEST_READINESS.md`, `STAGING_ACCESS_REQUIRED.md` and `PHASE7_HUMAN_EXECUTION_CHECKLIST.md`.

