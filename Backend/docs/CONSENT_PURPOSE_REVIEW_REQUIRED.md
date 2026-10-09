# Consent Purpose Review Required

Legal-document acknowledgement and optional purpose consent are separate controls. Signup acknowledgement is recorded by `consentService` against immutable `LegalDocumentVersion` and `ConsentEvent` records. Optional withdrawal is handled by the authenticated `/api/privacy-requests` workflow and `withdrawableConsentService`. The older mutable `/api/v1/privacy/consents*` and inline export routes now return `410 LEGACY_PRIVACY_FLOW_RETIRED`.

Legal/Privacy must approve, without relying on this repository as legal advice:

| Purpose | Current technical behavior | Decision required |
|---|---|---|
| Terms and privacy acknowledgement | Required, versioned signup evidence | Confirm acknowledgement wording and version publication |
| Profile matching | Local deterministic matching uses profile/preferences | Decide legal basis and whether withdrawal disables recommendations or requires account deactivation |
| Location discovery | Coordinates remain internal; public distance is five-km quantized | Decide legal basis, retention and exact withdrawal behavior |
| Marketing promotions | Notification preferences exist | Confirm opt-in/withdrawal channels and processor propagation |
| Analytics/diagnostics | No complete external analytics flow is source-proven | Approve only after SDK/runtime inventory |

Approval evidence must include purpose code, notice/version, legal basis decision, governed features/processors, propagation owner, retention consequence, approver, date and effective release. Tests must cover grant, withdrawal, re-consent, immutable history and cross-user denial.
