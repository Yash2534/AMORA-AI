# AMORAA — DATA INVENTORY & CLASSIFICATION CATALOG

## Overview
This catalog details all personal, sensitive, financial, and technical data attributes processed across the AMORAA ecosystem.

---

| Data Field | Purpose | Source Table | API Endpoint | Access Level | Retention Period | Classification |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Email Address** | Authentication, Communication | `Users` | `/api/auth/login`, `/api/users` | User, Admin | Account Lifetime | **Confidential** |
| **Phone Number** | Identity Verification, OTP | `Users` | `/api/auth/verify` | User, Admin | Account Lifetime | **Confidential** |
| **Password Hash** | Account Authentication | `Users` | `/api/auth/login` | System Only | Active Credential | **Restricted** |
| **Profile Photos / Bio** | Matchmaking & Discovery | `OnboardingProfiles` | `/api/profiles` | Public App | Active Profile | **Personal Data** |
| **Selfie & Govt ID** | Identity Verification | `IdentityVerifications` | `/api/identity-verification` | Compliance DPO | 30 Days Post-Review | **Restricted PII** |
| **Location Coordinates** | Nearby Discovery | `OnboardingProfiles` | `/api/discover` | User, System | Transient | **Sensitive PII** |
| **Payment History** | Billing & Invoicing | `Payments` | `/api/payments` | Finance Admin | 7 Years (Statutory Tax) | **Confidential Financial** |
| **User Consents** | DPDP Compliance Audit | `UserConsents` | `/api/v1/privacy/consents` | DPO, User | Compliance Audit Trail | **Legal Record** |
| **Privacy Grievances** | Grievance Redressal | `PrivacyGrievances` | `/api/v1/privacy/grievances` | DPO, Requester | 3 Years Post-Resolution | **Legal Record** |
| **Audit Logs** | Security & Accountability | `AdminAuditLogs` | `/api/admin/v1/audit-logs` | Super Admin | 1 Year | **Security Audit** |
