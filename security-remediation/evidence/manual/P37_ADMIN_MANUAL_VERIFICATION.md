# P-37 Admin Manual Verification

Use staging administrators with temporary roles; never use production or shared credentials.

- [ ] Consumer/normal user token denied — `P37_01_normal_user_denied.png`.
- [ ] Wrong admin role denied — `P37_02_wrong_role_denied.png`.
- [ ] Allowed role accepted only for mapped permission — `P37_03_allowed_role_accepted.png`.
- [ ] MFA challenge required where enrolled — `P37_04_admin_mfa_required.png`.
- [ ] Sensitive action requires fresh step-up where designed — `P37_05_fresh_mfa_step_up.png`.
- [ ] Access/refresh expiration, rotation, logout and revocation behave as configured — `P37_06_session_lifecycle.md`.
- [ ] Sensitive/destructive action appears in sanitized audit log with actor/target/correlation/outcome — `P37_07_audit_event_redacted.json`.
- [ ] Destructive workflow matches approved operational policy — `P37_08_destructive_workflow_approval.md`.
- [ ] No default/shared administrator exists; company roster has named accounts — `P37_09_admin_roster_redacted.csv`.
- [ ] Verification/chat/audit sensitive read is itself audited — `P37_10_sensitive_read_audit.json`.

Code proof: every admin route is behind the global admin boundary except explicit health/auth flows; permission matrix, MFA middleware, sanitized audit service and Phase 3 admin tests passed. Phase 4 adds generic coverage for any previously unaudited successful admin mutation/sensitive read and all 401/403 admin access attempts.

Organization roster, two-person approval decisions and company account ownership are not repository facts. Current status: **IMPLEMENTED — MANUAL EVIDENCE REQUIRED**.
