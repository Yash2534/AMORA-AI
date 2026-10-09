# API Security Coverage — Final Static Reconciliation

Count basis: 296 explicit declarations across `Backend/src/routes/*.js`, plus two direct `server.js` GET routes, plus seven additional concrete path patterns because `privacyRoutes` is intentionally mounted at both `/api/privacy` and `/api/v1/privacy`. This yields 305 concrete declared route patterns on 2026-10-09. Each `router.all` legacy pattern is counted once, not multiplied by verbs. The global 404 is not a route.

| Measure | Exact count | Interpretation |
|---|---:|---|
| Total concrete route patterns | 305 | 296 router declarations + 2 direct GET routes + 7 aliased privacy patterns |
| Authenticated or credential-bound | 279 | 165 admin-protected plus 114 user/session/opaque-token protected concrete patterns |
| Public intentionally | 26 | Health, config, signup/login/recovery/invitation/challenge, payment webhook, public legal/catalog routes; each has a bounded purpose |
| Admin protected | 165 | Global admin auth/origin plus explicit permission middleware; authenticated admin-auth self/session routes included |
| Active ownership/self/relationship protected user patterns | 114 | Authenticated non-admin concrete patterns; object routes enforce self, participant, owner, block/visibility, or service predicates as applicable |
| Disabled legacy concrete patterns | 8 | Four legacy consent/export declarations mounted at two aliases return 410 and cannot execute old handlers |
| Known active high-risk route missing auth/authorization | 0 | Source review and Phase 3 full regression found none |
| Staging header/topology evidence pending | 305 | Deployment behavior is not inferred from local source |

Validation is present where caller-controlled fields/IDs exist; input-free catalog/health/list endpoints rely on fixed controllers plus global payload/error controls. Every route inherits Helmet, restrictive CORS, 100 KiB JSON limit (multipart routes use file-specific limits), normalized error handling, and the 404 fallback. Sensitive route families have explicit rate policies where abuse risk requires them.

## Automated evidence

- Phase 3 backend full suite: 347 passed, 0 failed/blocked/skipped.
- Phase 4 backend full suite after event-coverage changes: 350 passed, 0 failed/blocked/skipped.
- Auth, cross-user/IDOR, invalid-ID, media traversal, privacy ownership, admin RBAC/MFA, CORS and error regressions are included in that suite.
- Phase 4 adds shared denied-sensitive-access, rate-limit and admin mutation/read event coverage.

## Residual evidence

- Staging captures of CORS, HSTS, CSP/security headers, proxy identity, payload rejection and sanitized 5xx responses.
- Human sign-off of the 305-pattern inventory at the release commit.
- The four legacy privacy declarations (eight concrete aliased patterns) remain intentionally disabled; removal can occur only after client/operational confirmation.

Status: **IMPLEMENTED — STAGING EVIDENCE REQUIRED**. No active high-risk repository route gap was found; production topology is not proven.
