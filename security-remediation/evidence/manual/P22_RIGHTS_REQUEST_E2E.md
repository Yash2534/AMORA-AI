# P-22 Data-Principal Rights Request E2E

Environment: staging with disposable users A/B; no production/customer data.

- [ ] A authenticates and creates ACCESS, EXPORT, CORRECTION, ERASURE/deletion, and WITHDRAWAL requests where the approved product flow supports them — `P22_01_request_types.png`.
- [ ] Anonymous creation/status access fails — `P22_02_anonymous_denied.png`.
- [ ] A cannot list/read/confirm/process/download B's request — `P22_03_cross_user_denied.json`.
- [ ] CREATED → VERIFIED → PROCESSING → COMPLETED/FAILED transitions match the canonical service — `P22_04_status_lifecycle.json`.
- [ ] Step-up confirmation expires and is one-time — `P22_05_step_up_expiry_replay.txt`.
- [ ] Export ownership, expiry and deletion pass — `P22_06_export_lifecycle.md`.
- [ ] Correction is owner-scoped and limited to supported fields — `P22_07_correction_scope.json`.
- [ ] Withdrawal changes the governed preference and appends immutable history — `P22_08_withdrawal_history.json`.
- [ ] Erasure routes to the approved deletion workflow and records outcome without deleting legally retained evidence prematurely — `P22_09_erasure_handoff.md`.
- [ ] Failure state contains a safe code, not personal data/stack trace — `P22_10_failure_sanitized.json`.

Repository evidence: Phase 3 owner/cross-user/status/step-up/export lifecycle tests passed. Counsel-approved deadline/SLA and operational queue evidence are not present.

Current status: **IMPLEMENTED — MANUAL EVIDENCE REQUIRED**; legal SLA remains **BLOCKED — LEGAL**.
