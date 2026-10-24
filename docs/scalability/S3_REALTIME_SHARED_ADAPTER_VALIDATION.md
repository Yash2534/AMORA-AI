# AMORAA S3 realtime shared-adapter validation

Date: 2026-10-12

Status: **BLOCKED — SHARED ADAPTER/PRESENCE INFRASTRUCTURE REQUIRED**

The repository accepts an injected Socket.IO adapter, but no adapter package/configuration is installed. Rooms, fanout and connection counts therefore remain process-local. This document does not designate Redis until infrastructure approval confirms the supported product/topology.

## Required design

- Authenticated/TLS shared Socket.IO adapter/pub-sub with bounded reconnect/backoff and adapter error metrics.
- User/admin/conversation room fanout across all instances.
- Presence records keyed by user and connection/instance with TTL/heartbeat; online means at least one live global connection. Disconnect cleanup must be idempotent, and crashed-instance entries must expire.
- Every client-relevant event carries a stable event/message identifier where deduplication is required. Durable message state remains MySQL-authoritative; pub/sub is delivery acceleration, not storage.
- Explicit outage policy: preserve HTTP/database writes, surface degraded realtime, avoid false offline transitions and recover subscriptions without an event storm.

## Two-instance validation

Connect sender to A and recipient to B. Validate message, read, notification, match, admin and presence fanout; multiple devices; duplicate subscriptions; reconnect to a different node; graceful A stop; abrupt A failure; adapter restart; stale presence TTL; blocked/deactivated authorization; and no cross-room leakage. Record event IDs, duplicate/missing counts, fanout latency and per-node/global socket metrics.

## Acceptance

Zero unauthorized events; every committed test message eventually observable by the authorized peer; duplicates are safely deduplicatable; online remains true while any connection exists; stale presence expires within the approved TTL; node removal does not require sticky routing; and adapter failure/recovery produces the documented degraded mode and alerts. None of these are currently proven across instances.

