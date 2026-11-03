# Dummy Administrator Setup Plan

Needed for P-37. Create in approved staging/test only; never grant production permissions.

| Identity | Permissions | Required state | Test purpose |
|---|---|---|---|
| ADMIN-LOW | Minimum restricted/read-only role | Active, MFA required | Prove restricted actions are denied and audited |
| ADMIN-FULL | Approved full role for reversible dummy actions only | Active, MFA required | Prove authorized action and audit path |
| MFA-ADMIN | Security-selected role | Active, dedicated test MFA and controlled recovery | Prove step-up, expiry and recovery behavior |

Use unique named identities; no shared/default password; password-manager-generated one-time setup; mandatory MFA; distinct role assignments; expiry/cleanup date; audit record for creation/role/MFA changes; and no production organization, data or permission. Provision through the interactive `Backend/scripts/create-admin.js` path or the approved admin workflow only after staging authorization. Do not log passwords, MFA seeds, recovery codes, cookies or tokens.

Pass prerequisites: roster owner approval, role-permission export, MFA enrollment evidence with secrets redacted, normal-user negative test, lower-role denial, authorized action, expired-session/step-up denial, sanitized audit events and account cleanup/disable record.
