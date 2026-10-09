# Admin Route Security Matrix

Global order for `/api/admin/v1`: audit context; public health/auth only; then administrator access-token/session validation; trusted-origin validation; route validation; explicit permission; controller. High-risk mutations listed below also require recent enrolled MFA through `adminMfaMiddleware`. Audit records must contain actor/action/target/outcome and sanitized metadata, never raw credentials, MFA material, identity numbers or message content unless an explicitly authorized content-view event requires it.

| Route family / exact direct paths | Auth | Permission | Fresh MFA | Audit / destructive classification |
|---|---|---|---|---|
| `GET /health`, `/auth/*` | Public health or admin-auth flow | Auth-flow specific | MFA challenge/enrollment rules in auth routes | Authentication events; not general admin access |
| `/users/*` | Global admin | Per-route `users.*` in `adminUserRoutes.js` | Required by route for destructive user action; matrix review pending for every mutation | User lifecycle is destructive/high risk |
| `/profiles/*` | Global admin | Per-route `profiles.*` | Required for destructive photo/profile changes where wired | Profile/identity data sensitive |
| `/verifications/*` and `GET /media/:mediaId` | Global admin | `verifications.*`; media uses `verifications.details.view` | Decision mutations must require step-up | Raw verification media highly sensitive |
| Financial/payment/membership routes | Global admin | `membership.*`, `payments.*`, `financial.*` per route | Required for mutations/refunds where wired | Financial action high risk |
| Administrator and role management | Global admin | `administrators.*`, `roles.*`, `permissions.*` | Create admin, assign roles, suspend/reactivate, revoke sessions, bulk changes, role/permission writes: yes | Privilege change/destructive; before/after audit required |
| Matching/discovery configuration | Global admin | `discover.*`/matching permissions | Setting mutations should require step-up | Product-wide behavior change |
| Safety routes | Global admin | `safety.*` | Account action endpoint: yes | Suspend/ban/deactivate destructive |
| Data-integrity routes | Global admin | Per-route integrity permission | Repair mutations require step-up | Data repair high risk |
| System routes | Global admin | `systemSettings.view/update` | Job retry: yes | Operational mutation |
| `GET/PATCH /system-settings` | Global admin | view/update | PATCH: yes | Product-wide security/config mutation |
| Audit log routes | Global admin | `auditLogs.view/details/integrity` | Read; no | Access itself audited; export permissions separate |
| `GET/PUT /privacy/grievances*` | Global admin | `privacy.grievances.view/manage` | PUT: yes | Sensitive case status/content |
| Chat moderation direct routes | Global admin | conversations/messages/search/reports permissions | Read/search; action routes elsewhere require step-up | Content access must be audited and minimized |
| Event direct routes | Global admin | `events.*` matching each action | create/update/publish/cancel/capacity/featured: yes | Publication/cancellation/capacity are high risk |
| Analytics direct/fallback routes | Global admin | `analytics.view` or narrower report permission | No | Read-only; sensitive exports need separate permission |
| Support fallback routes | Global admin | `support.*` | No for reads | Placeholder data only; still permission-gated |
| Content fallback routes | Global admin | `content.*` | No for reads | Placeholder data only; writes must be step-up gated when implemented |
| Notification fallback routes | Global admin | `notifications.*` | No for reads; launch/write must require step-up when implemented | Campaign launch high risk |

No two-person approval is claimed. Management must decide whether financial, role, ban, deletion, content publication and production-setting changes require a second independent approver. Until implemented and tested, that is an operational proposal rather than a completed control.
