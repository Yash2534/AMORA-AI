# AMORAA Manual Action Checklist

No checkbox below is pre-checked. Completion requires the stated evidence, an accountable reviewer, and a dated decision. Do not place secrets, private keys, recovery codes, live customer data, or raw identity documents in this repository.

## Management

- [ ] **Assign accountable security and privacy owners.** Owner: Executive management. System: organization roster. Steps: name primary and backup owners for security, privacy, grievance, moderation, incident command, backups, deployment approval and monitoring; define authority and offboarding. Evidence: signed roster stored in the controlled governance system, with a redacted reference under `evidence/management/`. Exit: every role in `MANAGEMENT_OPERATIONS_SIGNOFF.md` has a current owner and approver.
- [ ] **Approve residual risk and release authority.** Owner: Executive management. System: risk register. Steps: review all 51 control statuses and blockers; accept, reject or require remediation; name the person allowed to authorize a production release. Evidence: dated decision and risk references. Exit: no Critical/High risk is implicitly accepted.
- [ ] **Establish company-account custody.** Owner: IT/Management. System: provider account register. Steps: verify organization-owned email, MFA, recovery, least privilege and leaver process for hosting, DNS, stores, source control and vendors. Evidence: redacted account/MFA register. Exit: P-38 evidence accepted.

## DevOps and cloud infrastructure

- [ ] **Verify deployed TLS.** Owner: DevOps. System: every public API/admin/media hostname. Steps: test certificate chain, hostname, protocol/cipher policy, HTTP-to-HTTPS behavior and HSTS; record date and tool version. Evidence: redacted scan reports under `evidence/infrastructure/`. Exit: no production HTTP exception and approved TLS baseline passes.
- [ ] **Verify encryption at rest and KMS.** Owner: Cloud/DB owner. System: DB, object storage, backups, logs and queues. Steps: capture provider settings, key ownership, access policy, rotation and recovery procedure. Evidence: exports/attestations with account IDs and secrets redacted. Exit: P-04/P-08 reviewer approval.
- [ ] **Perform backup restore drill.** Owner: DevOps/DB. System: isolated non-production restore target. Steps: restore an approved backup, validate integrity/RPO/RTO, remove restored data safely, document failure handling. Evidence: timestamps, logs, validation results and approvals under `evidence/drills/`. Exit: successful tested restore without production/customer exposure.
- [ ] **Verify network and trusted-proxy boundaries.** Owner: Cloud/DB owner. System: load balancer, WAF, app and database. Steps: export firewall/security group/private-network rules; validate DB is not public; validate exact proxy hops; verify rate-limit client identity. Evidence: redacted diagrams/config exports. Exit: P-33/P-40 approved.
- [ ] **Verify production monitoring.** Owner: SRE. System: monitoring/on-call platform. Steps: enumerate security alerts, test delivery/escalation, validate log retention/access and current rota. Evidence: redacted alert test and rota reference. Exit: P-39/P-45 evidence approved.

## Database and data lifecycle

- [ ] **Approve data inventory and retention schedule.** Owner: Data owner with Legal/Privacy. System: database, storage, vendors, logs and backups. Steps: reconcile models/migrations/files to systems; decide retention/legal hold/deletion/anonymization per data class. Evidence: signed schedule and system inventory. Exit: P-19/P-21 decisions are explicit and executable.
- [ ] **Validate deletion and deactivation with dummy data.** Owner: Backend/Privacy. System: isolated test database and scratch storage. Steps: seed linked dummy users; execute deletion/deactivation/reactivation; inspect every linked table/file/session/provider reference. Evidence: redacted test transcript. Exit: approved behavior matches the data map, with no orphaned private artifacts.
- [ ] **Validate phone-number lifecycle.** Owner: Backend/Product. System: isolated auth/SMS test configuration. Steps: test number change, reuse, verification, account deletion and session revocation; ensure enumeration resistance. Evidence: test results. Exit: P-26 implementation and tests pass.

## Security engineering

- [ ] **Run the safe runtime plan.** Owner: Security engineering. System: compliant disposable harness. Steps: satisfy every prerequisite in `RUNTIME_VALIDATION_PLAN.md`; execute backend, Flutter, secret, dependency, SAST and SBOM suites; preserve exact exit codes. Evidence: redacted logs under `evidence/tests/` and `evidence/code/`. Exit: all required suites pass or findings are tracked; no skipped command is called a pass.
- [ ] **Review privileged access.** Owner: Security/Admin owner. System: application admin console and identity provider. Steps: reconcile roles/permissions to `Backend/docs/ADMIN_ROUTE_SECURITY_MATRIX.md`; verify MFA/fresh-MFA, break-glass, quarterly review and offboarding. Evidence: redacted roster/review. Exit: no undocumented or excessive privilege.
- [ ] **Validate logging and audit storage.** Owner: Security/SRE. System: application logs and audit sink. Steps: use synthetic secrets to confirm redaction; verify append/tamper controls, access, clock synchronization and retention. Evidence: synthetic test output and sink configuration proof. Exit: P-14/P-39 approved without exposing live secrets.
- [ ] **Commission independent VAPT and retest.** Owner: Security/Procurement. System: approved staging scope. Steps: contract independent qualified assessor; agree scope/rules; provide no production data; remediate findings; commission independent retest. Evidence: signed reports and closure letter in restricted storage, with redacted references under `evidence/vapt/`. Exit: P-46 and P-47 independently accepted.

## Legal and privacy

- [ ] **Verify current law and regulatory claims.** Owner: Qualified legal counsel. System: legal register. Steps: use current official sources and dated advice; verify DPDP/CERT-In applicability, effective dates, notification obligations, retention/location and penalty statements. Evidence: counsel approval with source citations. Exit: P-12/P-15/P-50 approved. The repository must not assert the held claims as facts before this step.
- [ ] **Approve policies, Terms and consent purposes.** Owner: Legal/Product/Privacy. System: controlled policy repository and product consent surfaces. Steps: approve authoritative text, purpose/legal basis, versioning, withdrawal effects, audience and publication date. Evidence: signed/versioned policies and UI mapping. Exit: P-17/P-18 approved and deployed version is traceable.
- [ ] **Approve deletion, grievance and identity-verification governance.** Owner: Legal/Privacy. System: lifecycle register, grievance process and verification vendor process. Steps: decide retention/legal holds/SLAs/access roles/liveness claims/vendor processing. Evidence: signed decisions and data protection review. Exit: P-19/P-27/P-32 governance blockers resolved.
- [ ] **Verify vendor contracts.** Owner: Legal/Procurement. System: contract repository. Steps: inventory processors/subprocessors; confirm executed DPA/security terms, purpose, region, retention/deletion, incident notice and exit obligations. Evidence: executed contracts in restricted storage plus redacted register. Exit: P-23 accepted.

## Product and safety operations

- [ ] **Approve AI data-flow register.** Owner: Product/Privacy/Security. System: matching/AI provider configurations. Steps: confirm actual outbound fields, provider/region, purpose, training/retention settings only from evidence, and minimization decisions. Evidence: approved register and provider proof. Exit: P-24 manually approved.
- [ ] **Staff moderation and anti-scam operations.** Owner: Safety management. System: moderation queues and escalation tools. Steps: set coverage, severity, escalation, quality review, law-enforcement process where approved, metrics and training. Evidence: staffing plan, runbooks and sample synthetic queue exercise. Exit: P-29/P-30 approved; no invented SLA.
- [ ] **Validate report/block/grievance workflows.** Owner: Safety/Support. System: non-production application and support tooling. Steps: test ownership, confidentiality, enumeration resistance, blocking effects and escalation with synthetic users. Evidence: walkthrough and test record. Exit: P-28/P-32 operational evidence accepted.

## Mobile and store release

- [ ] **Provision company-controlled signing.** Owner: Mobile release manager. System: protected CI signing service/keystore. Steps: generate or import company key outside Git; enforce least privilege, MFA, backup/recovery and rotation; configure release signing without committing credentials. Evidence: redacted signing verification and custody record. Exit: release artifact is not debug-signed and P-09/P-42 approved.
- [ ] **Validate final mobile release artifacts.** Owner: Mobile/Security. System: release APK/AAB/IPA and test devices. Steps: inspect merged manifests/entitlements/ATS/network security/exported components/backup/debug flags; test HTTPS guard and secure token lifecycle. Evidence: tool outputs and device test record. Exit: release checklist passes.
- [ ] **Complete store-console review.** Owner: Product/Mobile/Legal. System: Play Console and App Store Connect. Steps: verify organization ownership/MFA, privacy declarations, data safety/nutrition labels, account deletion URL, age/content ratings, support contacts and reviewer credentials. Evidence: dated exports/screenshots with sensitive fields redacted. Exit: P-41 approved by Product and Legal.

## Release engineering

- [ ] **Enforce repository protections.** Owner: Repository administrator. System: source-control host. Steps: require pull requests, independent review, passing security/test checks, signed/controlled merges where policy requires, restricted admins and protected tags/releases. Evidence: settings/ruleset export. Exit: P-43 external portion accepted.
- [ ] **Enforce deployment approvals.** Owner: DevOps/Release. System: real CI/CD platform. Steps: separate environments/secrets; require immutable artifact promotion, authorized approval, rollback and audit trail; prevent direct production deployment. Evidence: pipeline config and successful non-production promotion record. Exit: P-44 approved.
- [ ] **Apply final security gate.** Owner: Release authority. System: risk/release record. Steps: confirm every checkbox in `PRODUCTION_SECURITY_RELEASE_GATE.md`, unresolved findings, legal approvals, VAPT and rollback/monitoring readiness. Evidence: signed release decision. Exit: only a fully satisfied gate can change the recommendation.

## Incident response and support

- [ ] **Assign incident contacts and approve the plan.** Owner: Management/Legal/Security. System: restricted incident contact register. Steps: assign primary/backup incident commander, technical, legal, privacy, communications, support and vendor contacts; test access and escalation. Evidence: approved plan and contact-register reference. Exit: P-48/P-49 approved without committing personal contact details here.
- [ ] **Conduct a real tabletop exercise.** Owner: Incident commander. System: controlled exercise. Steps: choose one documented scenario; record participants, timeline, decisions, evidence handling, communications, gaps, owners and due dates; track actions to closure. Evidence: completed exercise record under restricted storage and redacted reference under `evidence/drills/`. Exit: P-51 has real—not fabricated—evidence.
- [ ] **Verify support confidentiality.** Owner: Support lead. System: grievance/privacy support queues. Steps: review access roles, ticket lookup, response templates, exports and retention; test with synthetic tickets. Evidence: access review and walkthrough. Exit: no requester PII leaks or public enumeration.

## External auditor

- [ ] **Reconcile evidence independently.** Owner: Independent auditor/assessor. System: repository commit plus restricted evidence room. Steps: sample every claimed implementation, reproduce permitted tests, validate external artifacts and identify contradictions/legacy bypasses. Evidence: signed assessment with scope and limitations. Exit: findings resolved or explicitly accepted by authorized management.
