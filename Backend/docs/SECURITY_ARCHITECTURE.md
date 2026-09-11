# AMORAA — SECURITY ARCHITECTURE & HARDENING SPECIFICATION

## Security Principles & System Architecture

AMORAA operates a defense-in-depth security architecture separating the Flutter Web Administration Client (`amoraa_admin_web`) from the Node.js / Sequelize API Gateway (`AMORA-AI/Backend`).

---

## Technical Security Controls

### 1. Authentication & Session Management
- **Password Security:** Password hashing using `bcrypt` ($12$ salt rounds). Raw passwords never stored or emitted.
- **Session Security:** Token-based authentication with `tokenVersion` invalidation. Revoked or expired sessions immediately return HTTP `401 Unauthorized`.

### 2. Authorization & Role-Based Access Control (RBAC)
- **Server-Side Authorization:** All administrative endpoints are guarded by server-side middleware (`requireAuth`, `requirePermission`, `requireSuperAdmin`).
- **Super Admin Protection:** The primary Super Admin account is protected against unauthorized role changes or account deletion.

### 3. API Hardening & Input Sanitization
- **HTTP Security Headers:** Integrated `helmet` middleware enforcing Content-Security-Policy (CSP), HSTS, and frame protection.
- **CORS Policy:** Explicit origin validation protecting against cross-origin data leaks.
- **SQL Injection Prevention:** Parameterized queries and model abstractions via Sequelize ORM.
- **IDOR / BOLA Prevention:** Resource ownership and authorization checked at database lookup boundaries.

### 4. Audit Logging & Credential Redaction
- **Immutable Log Storage:** Centralized recording of administrative actions in `AdminAuditLogs`.
- **Sensitive Field Redaction:** Automated redaction of `password`, `token`, `secret`, `authorization`, `otp`, and `cvv` attributes in `adminAuditService.js`.
