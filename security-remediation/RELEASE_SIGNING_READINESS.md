# Release Signing Readiness

Status: **BLOCKED — COMPANY SIGNING MATERIAL REQUIRED**

## Current configuration

`android/app/build.gradle.kts` reads four protected environment variables: `AMORAA_ANDROID_KEYSTORE_PATH`, `AMORAA_ANDROID_KEYSTORE_PASSWORD`, `AMORAA_ANDROID_KEY_ALIAS` and `AMORAA_ANDROID_KEY_PASSWORD`. A requested release task fails if any is absent; release builds set `isDebuggable = false`. No product flavors are defined. API environment selection uses `--dart-define=AMORA_API_BASE_URL=...`, and release mode rejects non-HTTPS or missing URLs. Firebase applies only when `google-services.json` exists.

The current machine has none of the four signing variables. Two identical historical APK paths exist and the Phase 6 evidence identifies the inspected artifact as Android Debug-signed. No AAB exists. The application ID remains `com.example.amora_ai`, so Release/Product must approve the final company namespace before store submission. The main manifest disables backup; secure-storage backup/transfer exclusions also exist.

## Production requirements

- Company—not an individual developer—owns the Play App Signing account/key custody, recovery and authorized signer roster.
- Keystore/private key material lives in an approved signing service, HSM/KMS-backed service or restricted CI secret/file store; never in Git, ordinary artifacts, chat, tickets or developer `.env` files.
- CI injects only into the protected release job, masks values, restricts logs/artifacts and records approver plus immutable source/artifact digest.
- Use separate staging and production provider credentials/config. Review Firebase public identifiers versus server secrets explicitly.
- Build from the approved commit with debug disabled and approved application ID/version/environment.

## Verification

APK:

```powershell
& 'C:\Android\Sdk\build-tools\37.0.0\apksigner.bat' verify --verbose --print-certs '<company-signed.apk>'
```

AAB:

```powershell
jarsigner -verify -verbose -certs '<company-signed.aab>'
```

Retain SHA-256, certificate fingerprints/subject, signing scheme result, build commit/version and controlled custody reference—not key material. Inspect merged manifest for `android:debuggable`, exported components, cleartext/network config and backup settings. Run the redacted artifact scan, endpoint/config inventory, Firebase review and public-client-ID classification. Any unexplained secret, debug certificate, non-HTTPS release endpoint or unapproved exported component fails the gate.
