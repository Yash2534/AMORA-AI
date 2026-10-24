# Realtime Multi-Instance Plan

Status: **PARTIAL — INFRASTRUCTURE REQUIRED**

S1 encapsulates the local socket registry, exposes an adapter injection point, makes conversation room subscription idempotent, and reports local socket counts. The Flutter client now delegates reconnect scheduling to Socket.IO with 1–30 second randomized backoff and eight attempts; the previous overlapping fixed two-second reconnect loop is removed. Desired conversation subscriptions are restored once per reconnection.

Process-local state remains:

- connected-user counts and online/offline transitions;
- Socket.IO rooms/fanout when no shared adapter is installed;
- admin rooms and user rooms;
- local connection metrics.

For 2+ instances, deploy and configure an approved Socket.IO shared adapter/pub-sub service. Presence needs shared, TTL-backed connection membership or a dedicated presence service; local zero-connections cannot mean globally offline. Validate cross-node message, read, notification, admin, and presence events, reconnects during node termination, duplicate suppression, adapter outage behavior, and rolling restart drain. Sticky sessions alone do not solve cross-node fanout or global presence.

Realtime scalability remains **INFRASTRUCTURE REQUIRED** until shared pub/sub is deployed and tested.
