# AMORAA Production Security Release Gate

## Current decision

**NOT PRODUCTION READY.** The appropriate recommendation is **READY FOR NEXT SECURITY VALIDATION STAGE**, not production release. No item below is implicitly satisfied by repository documentation.

## Blocking gate

- [ ] All repository-fixable P0 implementations have passed their required runtime and regression tests in the safe harness.
- [x] P-20 deactivation and P-26 phone lifecycle repository gaps are implemented and locally tested. P-26 operational policy approval and real SMS-provider staging evidence remain separate unchecked release requirements.
- [ ] No conflicting legacy route, public media path, plaintext token store, debug endpoint, credential fallback or authorization bypass remains.
- [ ] Backend full regression, Flutter analysis/tests, secret scan, dependency audit, SAST and SBOM generation have executed with recorded exit codes and accepted results. Phase 5 backend regression passes 356/356; Flutter tests pass 659 with 14 skips, but analysis still exits 1 with 44 pre-existing warnings/info and external scan/release evidence remains open.
- [ ] Production TLS, encryption at rest, KMS, private storage, database network, trusted proxy, distributed rate limiting, logging and monitoring evidence has been reviewed.
- [ ] Backup restore has been successfully exercised in an approved isolated environment.
- [ ] Company-controlled mobile signing exists; final Android/iOS artifacts and store declarations have been reviewed.
- [ ] Repository branch/ruleset protections and the real deployment approval pipeline are enforced and evidenced.
- [ ] Legal has approved the policies, consent purposes, retention/deletion, grievance, identity verification, vendor contracts and current regulatory interpretation.
- [ ] Management has assigned company account, moderation, anti-scam, grievance, incident, deployment, backup and monitoring owners with backups/offboarding.
- [ ] P-46 independent VAPT is complete and its report is accepted.
- [ ] P-47 independent retest confirms required remediation/closure.
- [ ] A real tabletop exercise has been completed and resulting actions are closed or formally risk accepted.
- [ ] All Critical and High findings are closed, or an authorized and time-bound exception exists in the controlled risk register.
- [ ] Rollback, alerting, incident contact access and post-release monitoring have been exercised.
- [ ] Authorized Security, Legal, Product, Operations and Release approvers have signed the same immutable release artifact/version.

## Unresolved P0 gate summary

Of the **35 original P0 controls**, **6 are COMPLETE — VERIFIED** (P-01, P-02, P-13, P-14, P-34 and P-35) and **29 remain open** in at least one verification dimension. In particular:

- P-06/P-07/P-10/P-11/P-16/P-25/P-31/P-37 await device, staging, scanner, infrastructure, approval or operational evidence. P-11's local Flutter suite passes, but staging traffic and release-device exit criteria remain open.
- P-13 repository event coverage now passes; production centralized/append-only sink controls remain open under P-39.
- P-22 and P-36 are P1 controls whose local DB suites passed but whose legal/staging sign-off evidence remains open.
- P-20 is COMPLETE — VERIFIED locally. P-26 has no remaining repository-code gap, but remains `IMPLEMENTED — OPERATIONS/POLICY SIGNOFF REQUIRED` pending Product/Security/Support approval and real SMS-provider staging proof.
- P-03/P-04/P-08/P-33 require infrastructure evidence.
- P-12/P-15/P-17/P-18/P-19/P-21/P-23/P-27/P-32 require legal verification or approval.
- P-05 requires a real restore exercise.
- P-09/P-28/P-29/P-30 require management/operations action.
- P-24 requires manual approval of the source-derived AI register.

## Sign-off record

| Role | Name/controlled reference | Decision | Date | Evidence reference |
|---|---|---|---|---|
| Security | TBD | NOT SIGNED | TBD | TBD |
| Legal/Privacy | TBD | NOT SIGNED | TBD | TBD |
| Product/Safety | TBD | NOT SIGNED | TBD | TBD |
| DevOps/SRE | TBD | NOT SIGNED | TBD | TBD |
| Mobile/Release | TBD | NOT SIGNED | TBD | TBD |
| Executive risk owner | TBD | NOT SIGNED | TBD | TBD |

Only genuine evidence and authorized human decisions may change this gate.

## Phase 6 gate note

The five manual-primary controls are P-09, P-16, P-22, P-25 and P-37. Phase 6 found no connected Android device, Android AVD or iOS device and received no staging authorization, dummy admin credentials, MFA device or human approvals. A pre-existing APK had zero high-confidence findings in a bounded redacted scan but is signed with the Android Debug certificate; no company-signed Android artifact or IPA exists. P-26 signoff remains entirely unsigned. Therefore no manual control or release-gate condition was newly closed.

## Phase 7 gate note

The exact staging-primary controls are P-11, P-31 and P-36. Phase 7 found Android tooling and local seed definitions, but no system image/AVD/device, approved staging hostname, validated dummy account environment, dummy admin/MFA identities, company signing configuration, AAB or IPA. No external endpoint was probed and no SDK package/key was installed. Setup, access and human-execution packs were created; these are not completion evidence. All Phase 6 manual/staging counts and the production decision remain unchanged.

## Phase 4 gate note

Backend regression is now 350/350 with the P-13 event matrix and persistence assertion passing. Exact P-06/P-07/P-16/P-22/P-25/P-31/P-36/P-37 evidence packs were generated, but none of their manual, staging, infrastructure, product, legal or management evidence was supplied. This does not change the current decision: **NOT PRODUCTION READY**; recommendation **READY FOR NEXT SECURITY VALIDATION STAGE**.

## Phase 8 gate note

Phase 8 identified the exact 13 infrastructure-primary controls and prepared staging, device, signing, account, owner, action and evidence packs. Local configuration confirms fail-closed production DB TLS, release HTTPS/signing guards, repository-side private media/export behavior, audit-chain logic and security workflow definitions. These facts do not prove deployed infrastructure.

No approved staging hostname, Android image/AVD/device, company signing material or AAB, dummy user/admin/MFA roster, provider console evidence, restore drill, central sink, monitoring/on-call, shared rate-limit store, branch-ruleset export or deployment/rollback record exists. Newly complete: **0**. Counts and the production decision are unchanged. **Phase 9 prerequisites ready: NO.**
