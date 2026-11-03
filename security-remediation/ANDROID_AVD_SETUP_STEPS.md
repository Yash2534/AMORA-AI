# Android Device / AVD Setup Steps

## Phase 8 discovery

- Android SDK: `C:\Android\Sdk`
- ADB: version 1.0.41 / 37.0.0 at `C:\Android\Sdk\platform-tools\adb.exe`
- Installed platforms: Android 34, 35 and 36
- Installed system images: **none found**
- Existing AVDs: **none listed**
- Connected Android devices: **none**
- Flutter targets: Windows, Chrome and Edge only

No SDK package was installed. ADB required an out-of-sandbox local-daemon check and returned an empty device list.

## Approval-gated setup

Recommended test baseline: an Android 14 / API 34 Google APIs x86_64 image, plus a physical Android 13+ device when permission/notification behavior must be representative. Mobile leadership may select API 35/36 instead; record the decision.

```powershell
& 'C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat' 'system-images;android-34;google_apis;x86_64'
& 'C:\Android\Sdk\cmdline-tools\latest\bin\avdmanager.bat' create avd --name amoraa_phase9_api34 --package 'system-images;android-34;google_apis;x86_64' --device pixel_6
& 'C:\Android\Sdk\emulator\emulator.exe' -avd amoraa_phase9_api34 -no-snapshot-load
& 'C:\Android\Sdk\platform-tools\adb.exe' wait-for-device
& 'C:\Android\Sdk\platform-tools\adb.exe' devices -l
flutter devices --device-timeout 10
```

Installation is intentionally not automatic because the system image is large and requires approval.

## App/evidence commands

Build only after non-production API configuration and signing intent are approved:

```powershell
flutter build apk --debug --dart-define=AMORA_API_BASE_URL=https://api-staging.<company-domain>
& 'C:\Android\Sdk\platform-tools\adb.exe' install -r '.\build\app\outputs\flutter-apk\app-debug.apk'
& 'C:\Android\Sdk\platform-tools\adb.exe' exec-out screencap -p > '.\security-remediation\evidence\manual\phase9-screen.png'
```

Replace the suggested hostname only with the approved value. Record SDK image/package hash, AVD name, API/ABI, app hash, tester, time and `Production accessed: NO`. Needed for P-16, P-25 and P-09 release-artifact/device verification.
