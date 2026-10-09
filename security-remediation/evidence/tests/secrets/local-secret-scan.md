# Local Secret Scan Evidence

- Date/time: 2026-10-09 11:42–11:46 Asia/Calcutta
- Commit: `eeeee8165714976a4cdad7d5a1dd460907c9bbf9` plus dirty remediation worktree
- Production accessed: **NO**
- Matched values recorded: **NO**
- Controls: P-01, P-10

Installed dedicated scanners: gitleaks **not found**; trufflehog **not found**; semgrep **not found**.

The current-tree path-only regex scan excluded dependency/build directories, lockfiles, the private local `.env`, and the unrelated Android build report. Results:

| Category | Paths | Result |
|---|---:|---|
| Private-key PEM header | 0 | No match |
| AWS access-key format | 0 | No match |
| GitHub token format | 0 | No match |
| Google API-key format | 0 | No match |
| OpenAI-style key format | 0 | No match |
| Generic credential assignment | 19 | Test/script paths only; values intentionally not emitted; manual fixture classification required |

A path-only history scan began across 157 commits. The AWS-format phase returned 18 false-positive paths inside historically committed generated/vendor JavaScript/WASM data. Remaining categories were stopped due excessive runtime. Git-history scanning is therefore **partial**, not passed.

Conclusion: no high-confidence secret pattern was found in the current scanned source, but P-10 still requires an approved dedicated scanner, complete history/build-artifact coverage, and external secret-store/rotation evidence.
