# P-31 Location Privacy Verification

Use synthetic coordinates and users only.

## Local/API evidence already passed

- Exact latitude/longitude/internal coordinates absent from public profile/discovery responses.
- Public distance is quantized to coarse buckets.
- Blocked, deactivated and deleted profiles are excluded.
- Local tests: location/discovery/public-profile regressions in the Phase 3 347-test suite.

## Manual staging/device evidence

- [ ] Capture redacted discovery JSON proving no coordinate fields — `P31_01_discovery_response_redacted.json`.
- [ ] Capture blocked user absent — `P31_02_blocked_user_absent.json`.
- [ ] Capture deactivated/deleted users absent — `P31_03_inactive_users_absent.json`.
- [ ] Inspect profile and discovery screens for exact location leakage — `P31_04_profile_discovery_ui.png`.
- [ ] Inspect chat/profile deep links — `P31_05_chat_profile_links.png`.
- [ ] Inspect privacy export field names for coordinate policy — `P31_06_export_location_fields.md`.
- [ ] Inspect application/security logs for raw coordinates — `P31_07_log_coordinate_scan.txt`.
- [ ] Product/Privacy approves the coarse distance representation — `P31_08_distance_product_approval.md`.
- [ ] Repeated-distance triangulation is tested and assessed — `P31_09_triangulation_test.md`.

No incognito behavior or triangulation resistance is claimed. Current status: **IMPLEMENTED — STAGING EVIDENCE REQUIRED**.
