# API Route Security Matrix

All mounted paths inherit Helmet, 100 KiB JSON limits (multipart routes have their own byte/file caps), restrictive CORS, normalized error handling and a 404 fallback. `publicMaintenance` does not replace authentication. Route declarations and their validators remain the executable source of truth.

| Mount/path family | Methods | Auth/ownership | Validation/rate policy | Sensitive behavior / residual check |
|---|---|---|---|---|
| `/api/auth/*` | GET/POST | Public auth; `/me`, logout, change-password require user token | body validators; login/signup/OTP/reactivation/password-change limiters | Enumeration-resistant auth responses; old sessions revoked after password change |
| `/api/onboarding/*` | GET/PUT/POST/DELETE | User token; own profile only | strict fields; shared age policy; photo MIME/signature/12 MiB/max-six; upload limiter | Completion must not bypass age/profile requirements |
| `/api/discover/*` | GET/POST | User token; eligibility, block, active status | filter/cursor validation; swipe limiter | Exact coordinates internal; public distance quantized |
| `/api/profiles/:userId` | GET | User token; active/completed/non-blocked target | positive integer ID | 404-equivalent denial prevents enumeration |
| `/api/me/profile`, `/preferences`, `/location` | GET/PUT/DELETE | User token; self only | field/coordinate bounds | Responses omit exact coordinates; location mutation remains internal |
| `/api/media/profile/:userId/:filename` | GET | User token; owner or visible/non-blocked active profile | integer owner; basename allowlist; media limiter | Private no-store response; stored-reference membership check |
| blocks/reports/relationships/matches | GET/POST/DELETE | User token; self/relationship target policies | ID/body validators; report/action limits | Cross-user object access requires service/controller predicates |
| conversations/messages | GET/POST/DELETE | User token; participant access | ID/body/media validation; message/media limits | Participant authorization and deleted/blocked lifecycle |
| events/subscriptions/payments/roses | mixed | Public catalog where declared; mutation requires user token | validators, payment webhook raw body, action limits | Payment signature/idempotency and owner scope |
| notifications/devices | GET/POST/PATCH/DELETE | User token; self only | validators | Device/token values never logged/exported |
| identity verification | GET/POST | User token; self submission | private storage; image signatures/types; 12 MiB; limiter | Liveness/vendor/retention remains external/product work |
| `/api/privacy-requests/*` | GET/POST | User token; request owner on every ID | type/ID/body validation; password step-up and one-time confirmation | Canonical access/export/correction/withdrawal lifecycle; exports expire/delete |
| `/api/v1/privacy` and `/api/privacy` notice/grievance | GET/POST | Notice public; grievance submit/status authenticated owner | grievance validation and limiter; legacy consent/export return 410 | Verified legal contact/SLA remains external |
| `/api/admin/v1/*` | mixed | See `ADMIN_ROUTE_SECURITY_MATRIX.md` | admin session/origin/RBAC/MFA/validators | Direct legacy gaps were permission-gated; full integration run pending |

Remaining route-wide exit evidence: mechanically enumerate every declaration, verify invalid IDs, anonymous access, cross-user ownership, production error bodies, CORS preflight and payload limits, then record executed results against the release commit.
