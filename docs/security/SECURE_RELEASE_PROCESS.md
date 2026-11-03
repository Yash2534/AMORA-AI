# Secure Release Process

Release inputs must identify the immutable Git commit, lockfiles, Flutter flavor/defines and backend environment schema. CI must run secret scan, dependency audit, SAST, backend tests against an isolated test database, Flutter analyze/tests and SBOM generation. Release artifacts must be built once, digest-bound to test results and promoted without rebuilding.

Production secrets and signing material come from protected external stores. Android release builds fail when the four `AMORAA_ANDROID_*` signing variables are absent; no key/password belongs in Git. A production approver verifies migrations, rollback, backup/restore readiness, monitoring, policy/store declarations, unresolved risk and independent VAPT state.

Rollback must use an approved prior immutable artifact and schema-compatible procedure tested on staging. A real dated rollback exercise, protected environment and approver record remain external release evidence.
