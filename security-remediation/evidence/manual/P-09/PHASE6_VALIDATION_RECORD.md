# P-09 Phase 6 Validation Record

- Control ID: P-09
- Date: 2026-10-09 13:51:43 +05:30
- Environment: Local Windows workspace; pre-existing Android release APK
- Tester: Codex local validation agent
- Dummy/test account used: None; static artifact inspection only
- Production accessed: **NO**
- Steps: identify existing Android release artifacts; hash the APK; verify its signature with Android build-tools 37.0.0; scan all 795 APK entries with the redacted high-confidence scanner; inventory iOS artifact availability.
- Expected result: company-signed Android and iOS release artifacts; valid release signatures; redacted source/package scans with no unexplained secret; documented public identifiers only.
- Actual result: `app-release.apk` SHA-256 `5BA137A21454A5C3DCDBA074915D8BB0A919DF55B1BD3D63E6FB105534518FA9`; signature verification succeeded but certificate DN is `C=US, O=Android, CN=Android Debug`; 795 entries scanned, 0 skipped for size, 0 high-confidence secret-pattern findings; no IPA or company-signed Android artifact was present.
- Screenshot/log filename: this record; `scan-apk-redacted.ps1`; command output retained in the Phase 6 report summary. No screenshot was fabricated.
- Pass/Fail: **FAIL / INCOMPLETE**
- Remaining dependency: company-controlled signed APK/AAB and signed IPA; custody proof; scan all final variants; reviewer approval; public-client-identifier inventory.

No secret value was printed or retained.

