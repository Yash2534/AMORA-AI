# Phase 2 Backend Full-Suite Evidence

- Date/time: `2026-10-09T12:10:03+05:30`
- Commit: `eeeee8165714976a4cdad7d5a1dd460907c9bbf9`
- Working directory: `D:\Projects\amora_ai\Backend`
- Command: `npm test`
- Environment: local repository; Node built-in test runner; serial execution
- Test data type: repository fixtures and attempted disposable test databases
- Production accessed: **NO**
- Exit code: `1`
- Duration: `51.722 s`
- Tests: `357`
- Passed: `114`
- Failed: `243`
- Skipped: `0`
- Result: **BLOCKED/FAILED — LOCAL MYSQL UNAVAILABLE**
- Relevant controls: P-06, P-07, P-13, P-16, P-18, P-19, P-20, P-22, P-25, P-27, P-31, P-32, P-34, P-35, P-36, P-37, P-39

The integration hooks consistently failed at `Backend/src/migrations/run.js` while connecting to `127.0.0.1:3306` with `connect EACCES`. Read-only discovery separately confirmed no listener, no MySQL/MariaDB executable, and no running Docker daemon. Hook-cleanup errors that follow are secondary to the failed setup. The 114 pure/unit tests passed, including P-01, P-02, P-14, age-policy, protected-path, location-serialization, export-TTL, trusted-proxy, and production database TLS-contract tests. No production database, API, account, credential, or cloud resource was used.
