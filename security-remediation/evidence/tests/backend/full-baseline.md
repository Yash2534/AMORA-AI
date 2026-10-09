# Backend Full Baseline Evidence

- Date/time: 2026-10-09 11:40:44–11:41:45 Asia/Calcutta
- Commit: `eeeee8165714976a4cdad7d5a1dd460907c9bbf9` plus dirty remediation worktree
- Command: `npm test`
- Working directory: `D:\Projects\amora_ai\Backend`
- Production accessed: **NO**
- Environment: development configuration; database host classified as loopback; fixed OTP test mode enabled; delivery skipped; live OTP disabled
- Exit code: **1**
- Duration: 53.067 seconds reported by Node
- Result: **113 passed, 243 failed at database setup, 0 skipped**

All observed failing DB-backed cases reported `connect EACCES 127.0.0.1:3306` from their setup/migration hook. Local MySQL was not reachable, so these are classified as **NOT VALIDATED — LOCAL TEST DATABASE UNAVAILABLE**, not as passed and not as confirmed application assertion defects.

The suites enforce distinct database names containing `test`; no production or non-loopback database was contacted. Relevant blocked areas include authentication/session revocation, media authorization, privacy exports and rights requests, consent, deletion/deactivation, location API responses, SQL-backed discovery, admin RBAC/MFA, and route ownership.
