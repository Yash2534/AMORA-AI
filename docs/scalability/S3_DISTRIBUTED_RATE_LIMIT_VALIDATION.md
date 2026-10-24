# AMORAA S3 distributed rate-limit validation

Date: 2026-10-12

Status: **BLOCKED — SHARED ATOMIC STORE REQUIRED**

S1 created named store-factory injection for route policies and a fail-closed `REQUIRE_DISTRIBUTED_RATE_LIMIT` flag. No shared store adapter is installed; current enforcement remains per process. Security control P-33 therefore remains infrastructure-evidence required.

## Store contract

Atomic increment with window expiry; policy-prefixed keys; consistent remaining/reset headers; TLS/authentication; bounded key length; no raw email/phone/token in persisted keys; latency/error/eviction metrics; and an explicit fail-open/fail-closed decision per policy. Login/OTP/account recovery/privacy-sensitive limits should normally fail closed or use a carefully bounded local fallback, while general availability limits require an approved threat/availability decision.

## Cross-node matrix

For login, signup, OTP request/verify/reset, privacy/export, profile/chat media and message policies: alternate requests between A and B using one normalized identity; confirm the fleet-wide threshold, one consistent 429 response, expiry/recovery and no reset on API restart. Repeat with distinct identities to detect key collision. Validate the exact edge proxy path and `TRUST_PROXY_HOPS`; spoofed forwarded headers must not change identity.

Pause the shared store in an approved test and capture response behavior, local resource impact, recovery, alerts and whether counters are lost. Never use real credentials or OTP destinations.

## Acceptance

Limits cannot be multiplied by node count; 429, reset and recovery match policy; key material is non-sensitive; store outage follows the approved mode; and metrics/alerts identify failures. Repository single-process tests are supporting evidence only, not this pass.

