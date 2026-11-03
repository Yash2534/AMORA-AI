# Account Deletion Data Map

This map is derived from the current model inventory. Legal retention decisions are deliberately unresolved.

| Data family | Repository models/files | Current technical action / required verification |
|---|---|---|
| Account/profile | `User`, `OnboardingProfile`, profile photos | Anonymize/delete via `immediateAccountDeletionService`; verify no protected media remains |
| Preferences/discovery | `DiscoverFilterPreference`, `DiscoverAction`, `SavedProfile` | Delete owner and target references; verify reverse references |
| Matches/likes | `Match`, relationship and rose records | Delete/anonymize both-sided references consistently |
| Chat/media | `Conversation`, `ConversationParticipant`, `Message`, `MessageMedia`, private chat files | Remove participation/content/media or apply an approved retained-evidence rule |
| Verification | `IdentityVerification`, decision events/reasons, private ID/selfie files | Remove raw files and identifiers; retention exception requires Legal/Privacy approval |
| Device/session/auth | `RefreshToken`, `UserDevice`, `OtpToken`, login events | Revoke credentials immediately; decide security-event retention/anonymization |
| Privacy/consent | `PrivacyRequest` family, `ConsentEvent`, `UserConsent`, grievances | Keep only approved evidence; anonymize requester fields where retention applies |
| Moderation/reports | `Report`, admin report cases/notes | Do not delete evidence arbitrarily; Legal/Safety must approve retention and pseudonymization |
| Audit/security | `AdminAuditLog`, `UserLoginEvent`, timelines | Retain/anonymize only under approved security/legal schedule |
| Payments/subscriptions | `Payment`, `PaymentEvent`, `Subscription`, entitlements | Financial/legal retention decision required; remove unnecessary profile linkage |
| Notifications/events | notification/delivery and event registration/waitlist rows | Delete or anonymize user linkage; cancel queued work |
| Files/artifacts | profile, chat, identity, privacy exports, cleanup tasks | Idempotent deletion with retryable `AccountDeletionFileTask`; verify failures and residual files |
| Vendors/backups | SMS/email/push/payment/hosting/backups | Processor deletion/expiry and backup aging are external evidence items |

Exit evidence: a seeded dummy-user test that enumerates every association before deletion, executes the canonical flow, verifies credentials are invalid, checks every approved deletion/anonymization predicate and file task, and records only non-secret counts. Retention of reports, audit, consent, grievance, financial or backup records remains `BLOCKED — LEGAL APPROVAL REQUIRED` until a signed schedule exists.
