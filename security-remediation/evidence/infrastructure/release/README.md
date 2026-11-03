# Release Infrastructure Evidence

- Acceptable: artifact SHA-256, company certificate fingerprints/subject, APK/AAB verification output, approved build/commit/version, manifest/config scan, redacted secret scan and custody/approval reference.
- Unacceptable: debug-signed or mutable artifact, private key/keystore/password, source-only claim, or scan of a different build.
- Redact: signing material, secrets, tokens and provider credentials; preserve artifact identity, certificate public metadata, scanner result and approval reference.
- Provider: Mobile/Release; reviewed by Security and company signing custodian.
- Pass: immutable company-signed artifact, debug off, approved endpoint/config/components, clean or dispositioned scans and verified custody.
