# Distributed Rate-Limit Evidence

- Acceptable: shared-store/private-network config, proxy topology, bounded cross-instance request/429 result, recovery/failure-mode and abuse alert.
- Unacceptable: process-local unit tests alone, production load tests, attacker-controlled header assumptions or unbounded traffic.
- Redact: credentials, tokens, internal details not required for review and dummy account secrets; retain instance/store aliases, counts, times and status/headers.
- Provider: Backend/DevOps; reviewed by Security.
- Pass: consistent shared thresholds across instances, correct source identity, safe 429 behavior, documented recovery and delivered alerts.
