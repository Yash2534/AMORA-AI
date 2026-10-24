# Distributed Rate-Limit Architecture

Status: **PARTIAL — INFRASTRUCTURE REQUIRED**

S1 gives every rate-limit policy a named, replaceable store factory while preserving the existing local MemoryStore behavior and all OTP, login, signup, privacy, media, payment, reporting, and message limits. `REQUIRE_DISTRIBUTED_RATE_LIMIT=true` fails startup until a real shared adapter is installed, preventing an operator from accidentally claiming multi-instance enforcement.

A production shared store must provide atomic increment/expiry, per-policy key namespaces, bounded outage behavior, TLS/authentication, latency and error metrics, and a tested failure policy. Redis is a likely implementation but is not selected or deployed by S1. P-33 security limits must retain their existing thresholds and normalized identity keys. Trusted proxy hops must stay explicitly configured so client IP keys cannot be spoofed.

Required staging evidence: two or more backend instances behind the intended proxy; a single identity exhausting a limit across alternating instances; window expiry; store outage behavior; OTP/login non-bypass; and rate-limit event metrics. Until this passes, horizontal rate limiting is not ready.
