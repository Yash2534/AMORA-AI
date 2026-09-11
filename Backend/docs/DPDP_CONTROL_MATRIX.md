# AMORAA — DPDP TECHNICAL CONTROL MATRIX

## Legal Position & Notice
> AMORAA's technical privacy and security controls have been reviewed and implemented in alignment with the Digital Personal Data Protection Act, 2023 and applicable DPDP Rules, 2025. Formal legal compliance remains subject to review by the organization's designated legal/privacy authority.

---

## DPDP Statutory Requirement vs Technical Implementation

| Section | Statutory Requirement | Technical Control Implementation | Status |
| :--- | :--- | :--- | :--- |
| **Section 5** | Notice prior to or at time of consent | Public DPDP Privacy Notice API (`GET /api/v1/privacy/notice`) returning itemized purposes, fiduciary identity, and Data Protection Officer (DPO) contact details. | **PASS** |
| **Section 6** | Purpose-specific consent & 1-Click Withdrawal | Purpose-coded `UserConsent` records timestamped with IP/User-Agent; 1-click withdrawal endpoint (`POST /api/v1/privacy/consents/withdraw`). | **PASS** |
| **Section 8** | Data Fiduciary Obligations & Data Minimization | Attribute exclusion in Sequelize ORM (`exclude: ['passwordHash', 'tokenVersion']`); strict API payload scoping and audit log credential redaction. | **PASS** |
| **Section 9** | Processing of Personal Data of Children | Age validation (18+ strictly enforced during onboarding and government ID verification). Processing, profiling, or targeted advertising to minors is prohibited. | **PASS** |
| **Section 11** | Data Principal Right to Access & Summary | Machine-readable JSON personal data export endpoint (`POST /api/v1/privacy/data-export`) delivering account attributes, consents, verifications, and payment logs. | **PASS** |
| **Section 12** | Right to Correction, Updating & Erasure | Controlled cascade anonymization workflow (`DELETE /api/account`) purging PII while preserving statutory financial records required by tax laws. | **PASS** |
| **Section 13** | Right to Grievance Redressal | DPO Privacy Grievance submission (`POST /api/v1/privacy/grievances`) and admin management portal (`/support/privacy-grievances`) with ticket tracking and SLA enforcement. | **PASS** |

---

## Technical Privacy Control Audit Metrics

- **Data Minimization:** Verified. Excludes sensitive hash/token data across 100% of API endpoints.
- **Audit Logging:** Verified. All administrative mutations recorded in `AdminAuditLogs` with actor details, IST timestamps (`Asia/Kolkata`), and redacted credentials.
- **Access Control (RBAC):** Verified. Server-side authorization enforced via `requireAuth`, `requirePermission`, and `requireSuperAdmin`.
