# AMORAA S3 slow-query monitoring

Date: 2026-10-12

Status: **BLOCKED — MYSQL 8 STAGING/TELEMETRY REQUIRED**

## Staging design

Enable provider-supported MySQL slow-query visibility or Performance Schema digest summaries only in approved staging. Start with a conservative observation threshold chosen by the DB owner, include non-indexed queries if safe, and review overhead. Never enable general query logging as a shortcut.

Export sanitized digest/fingerprint, execution count, total/average/p95 duration when supported, rows examined/sent, lock time, temporary-disk/table counts and first/last seen. Parameter values and raw SQL containing identity, contact, location, message, profile, payment or token data must not enter the central sink.

## Correlation and review

Correlate DB digests with normalized route/query class, deployment version, instance, dataset tier and test run ID—not user/request payload. Review top queries by total time, p95, rows examined and lock time after each representative plan run and S4 stage. Assign an owner and disposition: index/rewrite/bound/rollup/isolate/accept with rationale.

## Initial watchlist

Discovery compatibility/JSON/distance ordering; conversation unread counts; mark-read ranges; dashboard global counts; `GROUP BY DATE`; moderation/admin contains search and counts; recommendation attribution; financial reconciliation; privacy export reads.

## Evidence required

Sanitized DB configuration export, sample digest rows, retention/access controls, dashboard screenshot/export, redaction test, alert test and a ranked bottleneck register. None exists in this workspace, so no top staging bottleneck is claimed.

