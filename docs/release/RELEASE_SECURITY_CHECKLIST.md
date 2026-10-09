# Release Security Checklist

## Source and CI

- [ ] Immutable release commit reviewed; branch rules/export attached.
- [ ] Redacted secret/history scan clean or exceptions approved.
- [ ] Backend unit/integration/security tests passed against isolated test DB.
- [ ] Flutter analyze/tests passed; no release HTTP endpoint.
- [ ] Dependency audits/SAST/SBOM completed with tracked exceptions.

## Android/iOS

- [ ] Company Android keystore exists outside Git; custody/recovery owners recorded.
- [ ] Four protected `AMORAA_ANDROID_*` signing variables supplied; release signature verified; debug key absent.
- [ ] Merged Android manifest reviewed: exported launcher intentional, no unexpected exported components, `allowBackup=false`, secure-storage backup exclusions present, debug disabled.
- [ ] iOS entitlements/ATS/backup/keychain behavior and signed IPA reviewed.
- [ ] APK/IPA redacted secret and endpoint scan retained; only documented public client identifiers remain.

## Backend/data/privacy

- [ ] HTTPS/WSS/TLS/certificate evidence attached; production origins HTTPS-only.
- [ ] DB/storage/KMS/backup/network evidence attached.
- [ ] Private media, export expiry/deletion, session revocation, age/location, abuse and admin regression tests passed.
- [ ] Policies, consent purposes, retention, vendors, grievance contact and store declarations approved and match runtime behavior.

## Operations

- [ ] Monitoring/on-call/incident owners/contact test attached.
- [ ] Restore and rollback drills attached.
- [ ] Independent VAPT and independent retest attached; no open Critical; High resolved or formally approved.
- [ ] Release approver records residual risk and recommendation.

If the company signing key is absent, status is `BLOCKED — COMPANY SIGNING KEY REQUIRED`. Passing repository checks alone does not authorize production.
