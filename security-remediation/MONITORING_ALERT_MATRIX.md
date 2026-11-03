# Monitoring and Alert Matrix

Thresholds, destinations and owners must be approved in the monitoring platform. `TBD` values are not passes.

| Signal | Threshold | Severity | Alert destination | Owner | Runbook | Test method | Current status |
|---|---|---|---|---|---|---|---|
| Login abuse | TBD from baseline/risk | High | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Bounded failed-login dummy event | NOT CONFIGURED / EVIDENCE MISSING |
| OTP abuse | TBD from provider/rate policy | High | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Bounded dummy OTP threshold event | NOT CONFIGURED / EVIDENCE MISSING |
| Password-reset abuse | TBD | High | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Bounded dummy reset failures | NOT CONFIGURED / EVIDENCE MISSING |
| Admin login failure | TBD | High | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Dummy admin failed login | NOT CONFIGURED / EVIDENCE MISSING |
| Admin privilege change | Any successful/failed change, aggregation TBD | Critical | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Approved reversible dummy role event | NOT CONFIGURED / EVIDENCE MISSING |
| Sensitive export | Every generation/download/delete; anomaly threshold TBD | High | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Dummy privacy export lifecycle | NOT CONFIGURED / EVIDENCE MISSING |
| Media/storage exposure | Any public-policy or anonymous-access finding | Critical | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Safe policy check/known dummy object denial | NOT CONFIGURED / EVIDENCE MISSING |
| API failure spike | TBD by service baseline | High | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Controlled staging error event | NOT CONFIGURED / EVIDENCE MISSING |
| DB failure | Connection/error/saturation thresholds TBD | Critical | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Approved staging dependency interruption | NOT CONFIGURED / EVIDENCE MISSING |
| Service outage | Availability/SLO threshold TBD | Critical | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Synthetic staging health-check failure | NOT CONFIGURED / EVIDENCE MISSING |
| Rate-limit spike | TBD by route/principal baseline | Medium/High | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Bounded distributed 429 test | NOT CONFIGURED / EVIDENCE MISSING |
| Security event | Event-specific threshold TBD | High/Critical | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Emit approved dummy security event | NOT CONFIGURED / EVIDENCE MISSING |
| Audit integrity issue | Any verification failure | Critical | TBD | TBD — MANAGEMENT TO ASSIGN | TBD | Non-destructive test fixture or synthetic alert | NOT CONFIGURED / EVIDENCE MISSING |

P-45 passes only when each mandatory signal has an approved threshold/severity, real destination, named primary/backup owner, accessible runbook and successful staging delivery/escalation test.
