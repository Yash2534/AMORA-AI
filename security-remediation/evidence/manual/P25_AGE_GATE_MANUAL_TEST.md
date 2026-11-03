# P-25 Age Gate Manual Test

Server evidence is complete: shared `agePolicy` enforces UTC-safe exact-age boundaries in onboarding/profile/privacy correction paths, and Phase 3 API/DB mutation tests passed. This checklist covers the real user journey only.

- [ ] Exactly 18 today accepted — `P25_01_exactly18_allowed.png`.
- [ ] One day under 18 rejected — `P25_02_under18_rejected.png`.
- [ ] Future DOB rejected — `P25_03_future_dob_rejected.png`.
- [ ] Invalid/malformed DOB rejected — `P25_04_invalid_dob_rejected.png`.
- [ ] Editing/correction cannot bypass the rule — `P25_05_edit_bypass_denied.png`.
- [ ] Underage synthetic account cannot complete onboarding or enter discovery — `P25_06_underage_discovery_denied.json`.
- [ ] Error UI is clear and does not reveal internal state — `P25_07_error_ui.png`.
- [ ] Android journey matches API enforcement — `P25_08_android_flow.mp4`.
- [ ] iOS journey matches API enforcement where available — `P25_09_ios_flow.mp4`.

Do not create/retain a real minor's data. Product/Legal must approve underage response/deletion/appeal policy separately.

Current status: **IMPLEMENTED — MANUAL EVIDENCE REQUIRED**. Repository/server portion is verified.
