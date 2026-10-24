# Admin Route Security Matrix

R1 review date: 2026-10-12.

Global `/api/admin/v1` order is audit context, public health/auth exceptions, administrator access-token and active-session validation, trusted-origin validation, route validation, explicit permission, optional recent-MFA step-up, then controller. The shared access policy requires a valid HS256 token with the administrator issuer/audience/type, current unrevoked session, token-version match, active administrator, active role, current permission set, and consistent MFA state. UI visibility is never an authorization control.

| Method/path | Authentication / role | Permission | Resource scope | Sensitive data | Recent MFA |
|---|---|---|---|---|---|
| `GET /health`; `/auth/login`, refresh, reset, invitation, MFA login | Public auth flow with route-specific token/challenge and rate limits | Flow-specific | Presented credential/challenge | Credentials/session | Challenge rules |
| `/auth/me`, `/auth/mfa*`, `/auth/change-password`, `/auth/sessions*` | Current admin session and active role | Self-session scope | Authenticated administrator/session ID | Session/MFA | Disable, password change, recovery codes, session revoke |
| `GET /dashboard/*` | Global admin | `dashboard.view` | Aggregate only | Operational metrics | No |
| `GET/PATCH /system-settings`; `/system/*` | Global admin | `systemSettings.view/update` | Named allowlisted setting/job | Operational configuration | Mutations/retry |
| `GET /users`, `/:userId`, profile, sessions, login-history, notes, timeline | Global admin | Matching `users.*.view` | Path user ID; bounded query | Personal/session data | No for reads |
| User note mutations | Global admin | `users.notes.manage` | Path user/note IDs | Internal note | No |
| User suspend/deactivate/activate/force-logout/delete/reset-password | Global admin | Exact `users.*` mutation permission | Path user ID; transactional service | Destructive account/session | Yes |
| Profile list/detail/preview/photos/audit/taxonomy | Global admin | Exact `profiles.*` read permission | Path profile/photo ID | Personal/profile media | No for reads |
| Profile edit and photo add/reorder/remove/primary | Global admin | `profiles.edit` or `profiles.photos.manage` | Path profile/photo ID | Personal/profile media | Yes |
| Verification list/reasons/detail/history and protected media | Global admin | Exact `verifications.*.view` | Verification/media ID | Identity evidence | No for reads |
| Verification approve/reject/resubmission | Global admin | Exact decision permission | Versioned verification ID + idempotency key | Identity decision | Yes |
| Safety list/detail/queue/cases/counts | Global admin | Exact `safety.*`/`reports.view` | Case/report ID; personal search separately gated | Reports/evidence | No for reads |
| Safety assignment/status/account action | Global admin | `safety.reports.assign`, `safety.cases.update`, or `safety.actions.suspend` | Report and target IDs | Moderation/account lifecycle | Yes |
| Safety notes | Global admin | `safety.notes.manage` | Report ID | Internal note | No |
| Financial plans/offers/subscriptions/transactions/reconciliation/analytics | Global admin | Exact `membership.*`, `payments.*` permission; sensitive projections need dedicated permission | Plan/offer/subscription/transaction ID | Financial/provider reference | No for reads |
| Plan/offer create/update/status/delete and reconciliation investigation | Global admin | Exact mutation/audit permission | Named financial object | Financial configuration | Yes |
| Administrator list/detail/history/configuration | Global admin | Exact `administrators.*.view` | Administrator ID | Privileged identity/session | No for reads |
| Administrator create/assign/suspend/reactivate/revoke/bulk | Global admin | Exact administrator plus role permission where required | Administrator ID/version/idempotency | Privilege lifecycle | Yes |
| Role/permission reads | Global admin | Exact `roles.*`/`permissions.*` read | Role/permission ID | Authorization model | No |
| Role/permission writes and matrix save | Global admin | All required role/matrix permissions | Role/version/permission IDs | Authorization model | Yes |
| Audit list/metadata | Global admin | `auditLogs.view` | Bounded filters | Summary only; actor/context projections separately gated | No |
| Audit detail | Global admin | `auditLogs.details.view`; each section also needs `changes`, `requestContext`, `metadata`, or `actorDetails` permission | Audit event ID | Sensitive before/after/context | No |
| Audit integrity | Global admin | `auditLogs.view` or management integrity permission by route | Audit chain | Audit metadata | No |
| Discovery settings/filter reads | Global admin | `discover.settings.view` / `discover.filters.view`; sensitive projection separately gated | Named configuration | Matching configuration | No |
| Discovery settings/filter writes | Global admin | `discover.settings.manage` / `discover.filters.manage` | Versioned named field | Product-wide matching behavior | Yes |
| Matching actions/matches/score/history | Global admin | Dynamic action permission or exact matching permission; failure/explanation projections separately gated | Action/match ID | Matching rationale | No |
| Data-integrity overview/run-check | Global admin | `systemSettings.view/update` | Server-defined checks only | Operational data | Run-check: yes |
| Chat conversation/message/report reads/search | Global admin | Exact `chatModeration.*` | Conversation/message/report ID; controller scope | Message content | No; access audited |
| Event reads/options/attendees/waitlist/reminders/analytics | Global admin | Exact `events.*.view` | Event ID | Attendee data | No for reads |
| Event create/update/publish/cancel/capacity/featured | Global admin | Exact `events.*` mutation | Event ID | Publication/capacity | Yes |
| Privacy grievance list/update | Global admin | `privacy.grievances.view/manage` | Grievance ID | Privacy/legal case | Update: yes |
| Analytics snapshots/fallback reports | Global admin | `analytics.view` or narrower report permission | Server-defined report/page | Aggregated/sensitive metrics | No |
| Support/content/notification read fallbacks | Global admin | Exact support/content/notification read permission | Server-defined read-only response | Operational/content | No |

## Realtime administrator events

Administrator sockets use the same access validator. They do not join a global admin room. Current producers declare `verification.review`, `safety.reports.view`, or `users.view`; delivery revalidates session and current permission for every socket and disconnects revoked/disabled/roleless sessions. No client-selected room or query-string role is trusted.

## Explicit open governance items

No two-person approval is claimed. Management must decide whether financial, role, ban, deletion, publication, and production-setting changes require a second independent approver. Audit export is not implemented as a general route; if added, it must receive a separate explicit export permission. Executed route-matrix tests and operational access review remain required.
