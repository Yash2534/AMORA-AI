# P-22 Synthetic Test Data Plan

Use no real PII. Create only in approved staging under PRIVACY-REQUEST-USER plus USER-A/USER-B for boundary checks.

| Dataset/case | Synthetic content | Required outcome/evidence |
|---|---|---|
| User A | Fictional identity/profile/consent/activity | Owner can create and view only own request |
| User B | Distinct fictional records | Cross-user request/status/download denied without enumeration |
| Privacy request | Access/export/correction/erasure types and correlation IDs | Intake, identity step-up, status and audit lifecycle |
| Correction | One harmless synthetic profile field, before/after values | Authorized change and sanitized evidence |
| Export | Minimal approved synthetic account/profile/preferences/consents | Private generation, checksum, owner-only download |
| Erasure | Disposable linked rows/files | Approved delete/anonymize outcome and exceptions reference |
| Cross-user denial | USER-B attempts USER-A resource IDs | Uniform denial; no content or ownership leak |
| Expired artifact | Export with elapsed approved test TTL | 410/approved denial and storage deletion |
| Deleted artifact | Consumed/deleted export | Re-download denied; origin object absent |

Record build/commit, schema version, account aliases (not credentials), request/resource IDs where non-sensitive, expected/actual results, tester/time and cleanup. Legal deadline/retention approval and operational SLA remain separate required evidence.
