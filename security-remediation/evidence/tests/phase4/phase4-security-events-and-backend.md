# Phase 4 Security Event and Backend Evidence

- Date/time: 2026-10-09T13:01:49+05:30
- Commit: `eeeee8165714976a4cdad7d5a1dd460907c9bbf9` plus uncommitted remediation worktree
- Environment: Windows local development host; Node test runner; XAMPP MariaDB 10.4.32 on loopback; test-only schemas prefixed `amoraa_security_test`
- Test data: synthetic/dummy accounts and files only
- Production accessed: **NO**
- Relevant controls: P-13 primarily; regression coverage supports P-06, P-07, P-16, P-22, P-25, P-31, P-36 and P-37

## Commands and outcomes

| Command | Working directory | Exit | Outcome |
|---|---|---:|---|
| `node --test --test-concurrency=1 test/security-remediation.unit.test.js test/production-hardening.test.js` | `Backend` | 0 | 25 passed, 0 failed |
| affected DB/admin/privacy/identity suite (seven explicit test files) | `Backend` | 1 | One new assertion failed because MariaDB returned JSON metadata as text; application event existed. Assertion corrected to decode either representation. No protection weakened. |
| `node --test --test-concurrency=1 test/change-password.integration.test.js test/security-remediation.unit.test.js` | `Backend` | 0 | 20 passed, 0 failed; persisted password-change security event and no password leakage asserted |
| `npm test` | `Backend` | 0 | 350 passed, 0 failed, 0 skipped, 0 blocked; 215643.9692 ms |
| `npm test` (final post-middleware-order regression) | `Backend` | 0 | 350 passed, 0 failed, 0 skipped, 0 blocked; 180319.7669 ms |
| mechanical route declaration count + mount reconciliation | repository | 0 | 296 router declarations, 2 direct routes and 7 second-alias privacy patterns = 305 concrete patterns; 279 protected/credential-bound, 26 intentional public |
| `git diff --check` | repository | 0 | No whitespace errors; CRLF conversion warnings only |
| initial syntax batch | `Backend` | misleading aggregate 0 | Included `node --check server.js`, which failed because the correct path is `src/server.js`; not counted as a pass |
| corrected four-file `node --check` batch with fail-fast guards | `Backend` | 0 | Middleware, server and both changed test files parse successfully |
| `mysqladmin --protocol=tcp ... shutdown` followed by process check | repository | 0 | Local test-only MariaDB stopped cleanly after validation |

## New security-event assertions

- Critical user auth/account/privacy/safety/identity route outcomes map to bounded action/target metadata without copying request bodies.
- Status 429 maps to a rate-limit security event; admin and sensitive-path 401/403 map to denied-access events.
- Successful admin mutations and sensitive admin reads receive shared audit coverage where a domain service lacks an explicit audit call.
- Device identifiers are one-way SHA-256 references truncated to 24 hexadecimal characters.
- Password-change event persistence is correlated by response `x-correlation-id`; raw current/new passwords are absent from the serialized audit record.

Result: **PASS** for repository P-13 event coverage. Central production sink controls remain unexecuted P-39 infrastructure evidence.
