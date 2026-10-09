# Android Manual Test Readiness

Current state: **BLOCKED — DEVICE REQUIRED**

The SDK, ADB, emulator, `sdkmanager`, `avdmanager`, and Android platforms 34–36 are installed. No system image, AVD, or physical device is available. Phase 7 did not download packages or create a virtual device.

## Option A — create a dedicated test AVD

Run only after the workstation owner approves the SDK download and disk use:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
& 'C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat' 'system-images;android-35;google_apis;x86_64'
& 'C:\Android\Sdk\cmdline-tools\latest\bin\avdmanager.bat' create avd --name amoraa_api35_security --package 'system-images;android-35;google_apis;x86_64' --device 'pixel_7'
& 'C:\Android\Sdk\emulator\emulator.exe' -avd amoraa_api35_security -no-snapshot -wipe-data
```

Before app installation, confirm the AVD contains no personal account/data. Use only synthetic users. Configure the app for an isolated local backend or an explicitly approved staging hostname. Do not route to production.

## Option B — physical test device

1. Use a dedicated organization-controlled test device, not a personal phone.
2. Remove personal Google accounts, photos, contacts and notifications.
3. Enable USB debugging and approve only this workstation.
4. Confirm `adb devices -l` shows the intended serial.
5. Record model, Android version, security patch, build hash and tester.
6. Install only the approved test/release candidate and use dummy accounts.
7. Revoke debugging authorization and wipe test data after capture.

## Readiness gate

Do not begin P-11/P-16/P-25 captures until the device/AVD, build identifier, non-production endpoint, synthetic accounts and evidence owner are recorded. Screenshots must exclude tokens, OTPs, passwords, personal photos, notification content and customer data.

