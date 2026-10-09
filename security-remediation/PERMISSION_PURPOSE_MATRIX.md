# Permission Purpose Matrix

This is a technical source inventory, not a legal-basis determination. Product/Privacy must approve necessity and wording on release devices.

| Permission | Platform | Feature | Why required | When requested | Optional/required | Denied behavior | Limited-access behavior | Data collected | Retention implication | Current status |
|---|---|---|---|---|---|---|---|---|---|---|
| Internet | Android/iOS entitlement | API, media, notifications | Network service operation | No runtime prompt | Required for online service | App cannot reach service | N/A | Request/response data | Server policies apply | Declared/implicit; source verified |
| Camera | Android/iOS | User-selected profile photo or verification selfie | Capture a new image | Only after camera action | Optional until user selects feature | Picker stops with typed message | Restricted/permanent denial offers settings | Selected image only | Uploaded copy follows profile/identity rules | Source + Flutter tests pass; device evidence pending |
| Coarse location | Android | Discovery distance/location choice | Calculate match distance when enabled | Feature/toggle action | Optional | Feature remains off; typed feedback | One-time behavior needs device test | Position supplied to location API | Internal coordinate lifecycle requires Product/Privacy approval | Source tested; device evidence pending |
| Fine location | Android | Same foreground location flow | More accurate distance calculation | Requested through foreground location permission | Optional | Same as coarse denial | Approximate/precise toggle behavior needs device test | Position accuracy depends on OS choice | Exact coordinates remain internal; public output coarse | Manifest/source verified; necessity of fine precision needs Product approval |
| When-in-use location | iOS | Discovery distance/location choice | Foreground position only | Feature/toggle action | Optional | Feature remains off | Approximate location behavior requires device test | Foreground position | Same as Android | Purpose string/source verified; device evidence pending |
| Notifications | Android/iOS | Messages, matches, account updates selected by user | Deliver opted-in push alerts | Notification preference enable/sync, once per session | Optional | Push remains disabled; other channels unaffected | Provisional iOS state treated as allowed; verify device UX | Push token and delivery metadata | Token removed by lifecycle paths; provider retention unverified | Source/Flutter tests pass; device evidence pending |
| Photos / selected media | Android/iOS | Profile and verification image selection | User chooses an existing image | Only after gallery action | Optional | Picker stops with typed message | Android system picker limits to selection; iOS limited library must be verified | Selected image bytes; metadata request disabled | Uploaded copy follows relevant media lifecycle | Source/Flutter tests pass; device evidence pending |
| `READ_MEDIA_IMAGES` | Android 13+ manifest | Compatibility for image selection | Present in manifest, while application code prefers system picker | Should not be prompted when system picker is used | Candidate for removal after merged-manifest/device confirmation | System picker should still work | Selected-only | Selected images | Broad grant should not be retained/used | MANUAL PRODUCT/DEVICE REVIEW REQUIRED; broad permission may be unnecessary |
| Remote-notification background mode | iOS | Receive supported push notifications | OS delivery integration | No direct permission beyond notifications | Optional feature | No push delivery | Provisional behavior needs device test | Push delivery metadata | Provider/server lifecycle applies | Source verified; signed-build/device evidence pending |

## Manual release-device checks

- [ ] Android and iOS ask for location only after the user starts a location-dependent feature.
- [ ] Camera and gallery prompts occur only after the corresponding picker action.
- [ ] Android image selection uses the system picker without broad gallery access; determine whether `READ_MEDIA_IMAGES` can be removed.
- [ ] Notification denial leaves the toggle off and does not repeatedly prompt in one session.
- [ ] Denied, permanently denied, restricted, approximate/precise, one-time, and iOS limited-library states show safe behavior.
- [ ] No background-location, contacts, microphone, SMS, call-log, broad storage, or all-files permission appears in merged release artifacts.

Status: **IMPLEMENTED — MANUAL EVIDENCE REQUIRED**.
