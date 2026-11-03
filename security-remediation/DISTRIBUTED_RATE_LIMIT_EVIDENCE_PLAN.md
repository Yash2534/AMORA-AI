# Distributed Rate-Limit Evidence Plan

Control: P-33. Current status remains infrastructure-evidence pending.

The repository defines route-specific limits and local 429 responses, but the installed middleware currently uses its default process-local store. Production-scale closure requires a Redis/shared store or equivalent.

## Required validation

1. Record approved proxy chain and trust-proxy configuration; demonstrate that client-supplied forwarding headers cannot select another identity.
2. Configure a shared store with authentication, TLS/private networking, environment isolation, least privilege, expiry and health monitoring.
3. Run bounded synthetic requests across at least two staging API instances and prove the same principal consumes one shared threshold.
4. Verify consistent 429 body/headers and retry behavior without exposing account existence.
5. Exercise store restart/unavailability and document the approved fail-open/fail-closed behavior, recovery time and alert.
6. Verify login, OTP, password-reset, media, messaging and other sensitive limit spikes generate actionable abuse telemetry.

Do not load-test a shared or production service. Use an approved staging window and a bounded request count. Retain sanitized topology/config, instance IDs, timestamps/counts, 429 results, recovery and alert-delivery evidence.
