# Backend Security Unit and Hardening Evidence

- Date/time: 2026-10-09 11:29–11:47 Asia/Calcutta
- Commit: `eeeee8165714976a4cdad7d5a1dd460907c9bbf9` plus dirty remediation worktree
- Working directory: `D:\Projects\amora_ai\Backend`
- Production accessed: **NO**
- Test data: synthetic origins, dates, tokens, credentials and object fixtures only
- Controls: P-01, P-02, P-06, P-07, P-14, P-25, P-31, P-33

## Executions

| Command | Exit | Result |
|---|---:|---|
| `node --test --test-concurrency=1 test/security-remediation.unit.test.js test/production-hardening.test.js` | 1 | 19 passed, 1 failed: logger callback incorrectly received the `Array.map` index as its `seen` parameter |
| Same command after narrow logger fix | 0 | 20 passed, 0 failed |
| Same command with socket-based preflight test | 1 | 20 passed, 1 blocked by loopback TCP `EACCES` |
| Same command with in-process CORS fixture | 1 | 20 passed, 1 failed because the test expected rejected preflight middleware to short-circuit with 204 instead of calling the next handler |
| Same command after correcting the fixture expectation | 0 | **21 passed, 0 failed, 0 skipped**; TAP duration 1649.302 ms |

## Verified assertions

- production never enables the development admin seed;
- development seed requires explicit email/password and rejects a short password;
- logger and admin-audit sanitizers recursively redact sensitive keys and identity numbers;
- logger output does not contain the supplied synthetic credential marker;
- production origin configuration rejects HTTP, wildcard and unlisted origins;
- allowed HTTPS preflight receives the correct allow-origin header; rejected origins receive none;
- exactly-18 date boundary is accepted and underage/future/invalid dates are rejected;
- media path references reject traversal and produce protected routes;
- coarse distance helper does not serialize exact coordinates;
- privacy-export TTL bounds are enforced;
- trusted-proxy configuration fails closed;
- production database configuration requires verified TLS material.

## Code corrections prompted by the run

1. `Backend/src/utils/logger.js`: wrapped sanitizer calls so `Array.map` cannot pass its numeric index as the cycle-detection argument.
2. `Backend/test/security-remediation.unit.test.js`: added deterministic, in-process production CORS preflight coverage.

The failed attempts remain disclosed; only the final execution is a pass.
