# Phase 7 Human Execution Checklist

Use synthetic identities only. Record tester, date/time, build/commit, device/environment, expected/actual result, pass/fail, remaining dependency and `Production accessed: NO` in every evidence item. Redact passwords, OTPs, tokens, cookies, API keys, personal data and exact coordinates.

## ANDROID DEVICE

| Control | Prerequisite | Steps | Expected result | Evidence filename | Who performs it | Pass criteria | Current blocker |
|---|---|---|---|---|---|---|---|
| P-11 | Approved release candidate, Android test device/AVD, approved non-production endpoint | Capture HTTPS traffic; inspect endpoint; login/logout/delete/password lifecycle; inspect secure-storage clearing | HTTPS only; tokens only in platform secure storage; lifecycle clears/revokes credentials | `P11_android_https_secure_storage.txt` | Mobile + Security | No HTTP, plaintext token or retained credential | No device/AVD, staging or company-signed build |
| P-16 location | Device/AVD with reset permissions and synthetic profile | Navigate to location feature; capture pre-prompt rationale; deny; retry; allow while-in-use | No startup prompt; denial handled without crash; retry contextual; no background request | `P16_location_permission_denied.png` | Mobile + Product/Privacy | Prompt and behavior match approved purpose | No device/AVD or approval |
| P-16 camera | Device/AVD | Open camera-dependent action; deny then allow | Only contextual request; clear rationale; no crash/unrelated permission | `P16_camera_permission_allowed.png` | Mobile + Product/Privacy | Contextual, minimal and denial-safe | No device/AVD or approval |
| P-16 media | Android version supporting selected photos where applicable | Use picker/limited selection; deny and retry | System picker/least privilege; no broad storage access; denial-safe | `P16_photo_selected_access.png` | Mobile + Product/Privacy | Minimal access and approved purpose | No device/AVD or approval |
| P-16 notifications | Android 13+ device/AVD | Reach notification context; deny; retry from settings | No unrelated startup prompt; app remains usable after denial | `P16_notification_permission_denied.png` | Mobile + Product | Contextual and denial-safe | No device/AVD |
| P-25 | Device/AVD, isolated backend/staging, disposable users | Exercise exact-18, under-18, future, malformed, DOB edit and discovery paths | Exact 18 accepted; invalid/underage rejected with clear UI; no discovery bypass | `P25_exact18_allowed.png`, `P25_under18_rejected.png` | Mobile + Product | All boundaries and UI outcomes proven | No device/AVD/staging/policy |

## ADMIN

| Control | Prerequisite | Steps | Expected result | Evidence filename | Who performs it | Pass criteria | Current blocker |
|---|---|---|---|---|---|---|---|
| P-37 normal user | Approved staging/admin client and normal dummy user | Attempt admin login/API | Denied without enumeration or sensitive detail | `P37_normal_user_denied.png` | Security + Admin owner | Consistent deny and sanitized audit | No staging/admin UI/account |
| P-37 lower role | Lower-privilege dummy admin with MFA | Authenticate and attempt restricted action | Role denied; audit contains sanitized actor/action/target/outcome | `P37_wrong_admin_role_denied.png` | Security + Admin owner | No permission bypass | No dummy admin/MFA/roster |
| P-37 authorized role | Authorized dummy admin | Authenticate with MFA and perform approved non-destructive action | Allowed only after correct role/MFA | `P37_authorized_role_allowed.png` | Admin owner + Security | Intended action succeeds and is audited | No dummy admin/MFA |
| P-37 step-up/session | Authorized dummy admin | Let session/step-up expire; retry sensitive action; reauthenticate | Expired context denied; fresh MFA restores only intended authority | `P37_mfa_required.png`, `P37_session_expired.png` | Security | Expiry and step-up enforced | No staging/MFA device |
| P-37 destructive workflow | Authorized dummy admin and disposable target | Execute approved reversible/destructive dummy action | Correct step-up/permission; before/after audit; no secret/PII leakage | `P37_destructive_action_audit.json` | Admin owner + Security | Complete sanitized audit and approved workflow | No environment/owner approval |

## STAGING

| Control | Prerequisite | Steps | Expected result | Evidence filename | Who performs it | Pass criteria | Current blocker |
|---|---|---|---|---|---|---|---|
| P-11 | Explicit staging hostname and release devices | Repeat Android/iOS HTTPS and credential-lifecycle checks | HTTPS/WSS and secure token lifecycle on both platforms | `P11_staging_transport_storage.txt` | Mobile + DevOps/Security | No cleartext endpoint/token retention | No approved staging/device |
| P-22 | Approved staging, Users A/B, privacy operations queue | Create access/export/correction/erasure/withdrawal requests; status; cross-user; expiry/deletion; completion | Ownership enforced, no enumeration/PII leakage, valid lifecycle | `P22_cross_user_request_denied.json` | Privacy Operations + Product | All technical checks pass; legal SLA separately approved | No staging/accounts/ops/legal approval |
| P-31 | Approved staging and active/blocked/deactivated/deleted dummy users | Capture public responses, UI, logs and export | Exact lat/long absent publicly/logs; exclusions work; distance coarse | `P31_location_api_redacted.json` | Backend + Product/Privacy/Security | No exact-coordinate exposure; approved precision | No approved staging/Product approval |
| P-36 | Approved staging/proxy and Users A/B | Record HTTPS, CORS, headers, OPTIONS, unauth/auth/cross-user, invalid IDs, validation, 5xx sanitization, bounded 429 | Edge and app controls match route matrix; no stack/ownership leak | `P36_cors_https_headers.txt` | Backend + DevOps/Security | Every sampled route meets matrix; no destructive testing | No approved staging/topology |
| P-26 | Approved staging SMS provider and dummy numbers | Request/confirm change; wrong/expired/replay; support escalation | Provider delivery and operational policy behave as signed | `P26_staging_phone_change.txt` | Product + Security + Support/Ops | Technical and approved operational flow pass | No staging/provider/approvers |

## RELEASE ARTIFACT

| Control | Prerequisite | Steps | Expected result | Evidence filename | Who performs it | Pass criteria | Current blocker |
|---|---|---|---|---|---|---|---|
| P-09 | Final company-signed APK/AAB and IPA | Hash/signature verify; scan assets/manifest/strings/config/endpoints; classify public IDs; retain redacted results | No server secret/private key/unapproved endpoint; correct company signatures | `P09_release_binary_scan.txt` | Mobile + Security/Release | All final variants clean or approved exceptions | Only debug-signed APK; no AAB/IPA/key custody |
| P-42 | Same signed artifacts plus merged manifests/entitlements | Verify signing/debuggable/exported/backup/ATS/entitlements | Company signature; debug off; intentional components; secure backup/network settings | `P42_signed_artifact_review.txt` | Mobile + Release/Security | All release checks and custody pass | No company artifacts/keys |

## MANAGEMENT APPROVAL

| Control | Prerequisite | Steps | Expected result | Evidence filename | Who performs it | Pass criteria | Current blocker |
|---|---|---|---|---|---|---|---|
| P-16 | Device captures and permission-purpose matrix | Product/Privacy review necessity and copy | Signed purposes and least-privilege decision | `P16_permission_purpose_approval.md` | Product + Privacy | Every permission has approved need/behavior | No captures/approvers |
| P-25 | Device journey and underage workflow proposal | Approve rejection/deletion/support behavior | Signed underage lifecycle decision | `P25_underage_policy_approval.md` | Product + Legal | UI/runtime matches approved policy | No policy approval |
| P-26 | Completed signoff form and provider evidence | Review every phone-reassignment scenario | Three authorized approvals | `P26_operations_signoff.pdf` or controlled reference | Product + Security + Support/Ops | All items signed; open risks assigned | No approvers/provider evidence |
| P-37 | Admin captures and current roster | Approve roles, destructive governance and account ownership | Current least-privilege roster and decision | `P37_admin_role_approval.md` | Admin owner + Security/Management | No shared/default/excessive account | No roster/approvers |

No checkbox is pre-marked. A template or repository test is not human/device/staging completion evidence.

