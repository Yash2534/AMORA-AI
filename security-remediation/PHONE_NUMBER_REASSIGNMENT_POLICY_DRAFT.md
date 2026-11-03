# AMORAA Phone Number Reassignment Policy Draft

Status: **DRAFT — PRODUCT/SECURITY/SUPPORT APPROVAL REQUIRED**  
Scope: AMORAA user phone ownership, change, recovery and disputed/recycled-number handling  
This draft is an operational proposal, not a legal conclusion or an approved Support procedure.

## Repository controls already enforced

- Supported Indian mobile numbers are normalized to canonical `+91XXXXXXXXXX` form before identity lookup or persistence.
- Non-empty canonical phone ownership has a database uniqueness boundary.
- A signed-in user must complete provider-appropriate step-up authentication before a new-number OTP is issued.
- The existing number is not replaced until the new-number OTP succeeds inside the final ownership transaction.
- A successful phone change increments the session version, removes refresh sessions and device registrations, creates a sanitized audit event and attempts a security notice to the account email.
- Password recovery remains email-based. Possession of a phone OTP alone does not reset a password or expose an existing account.
- No endpoint automatically transfers a number already owned by another active or deactivated account.

## Duplicate-number case

1. Return a non-enumerating “phone unavailable” response; do not disclose the owning account.
2. Do not detach or transfer the number automatically.
3. Create a sanitized duplicate-claim security event containing a one-way phone reference, claimant user ID and correlation ID—never the OTP or raw phone number.
4. Direct the claimant to the approved Support channel after that channel and its authentication standard are formally approved.

## Lost-number case

1. A signed-in user who still controls the account may change the number only through provider-appropriate step-up and OTP verification of the new number.
2. A signed-out user must use an already-approved recovery factor. Phone possession by itself must not reveal or restore the account.
3. Support must not bypass the uniqueness boundary or directly edit the database.

## Recycled-number claim

1. Treat receipt of an OTP as evidence of current control of the number, not proof of ownership of any pre-existing AMORAA account.
2. Never expose the prior account, email, profile, messages or existence details to the claimant.
3. If the number is already attached to another account, hold the claim for an approved escalation process; do not reassign automatically.
4. Any approved reassignment mechanism must revoke prior sessions/devices, preserve an audit record, notify available prior contact channels when policy permits, and avoid revealing either party’s personal data.

## Account recovery

- Prefer the existing provider identity for Google accounts and the approved email recovery flow for local accounts.
- Require a fresh, bounded recovery authorization before any identity-field change.
- Do not accept screenshots, caller ID, contact-list entries or OTP possession alone as proof of entitlement to the old account.
- Do not ask for passwords, OTPs, tokens or full identity-document numbers through Support messages.

## Disputed ownership

1. Freeze reassignment only through an approved, auditable Support capability; no such administrative reassignment capability is implemented by this repository phase.
2. Assign a case identifier and restrict case visibility to authorized Support/Security roles.
3. Record the claimant, affected account reference, decisions, actor, timestamps and reason without raw credentials or unnecessary identity data.
4. Escalate conflicting claims to Security and the designated privacy/legal reviewer before any transfer.

## Evidence Support may request

Product, Security, Privacy and Legal must approve the minimum evidence set. Potential categories for approval—not current requirements—include:

- successful authentication with an existing account provider;
- control of an already-verified account email;
- transaction or account-history facts already held by AMORAA that can be checked without disclosing them;
- carrier evidence only if Legal/Privacy approve its necessity, collection method, retention and access restrictions.

Do not invent government-ID, SIM-registration or notarization requirements. Do not collect identity documents until an approved purpose, retention period and restricted storage workflow exist.

## Escalation and privacy safeguards

- Tier 1 Support: receive the request, prevent enumeration and collect only approved minimum fields.
- Security: review takeover indicators, session history and sanitized audit events.
- Privacy/Legal: approve any exceptional evidence collection, disclosure or retention.
- Product/Support leadership: approve or reject the operational transfer and user communications.
- Restrict access by role, redact raw phone numbers in general logs, and prohibit OTP/password/token collection.

## Required effects of an approved reassignment

- Atomically establish one canonical owner.
- Increment the affected account session/token version.
- revoke refresh sessions and device/push registrations;
- invalidate pending phone-change OTPs;
- create a sanitized, immutable audit event;
- notify approved prior/current contact channels without disclosing the claimant;
- document the decision, approver and evidence retention/deletion date.

## Approval record

| Decision | Owner | Evidence required | Status |
|---|---|---|---|
| Recovery factors and minimum claimant evidence | Product + Security + Privacy/Legal | Approved procedure/version | TODO |
| Support roles and access permissions | Support leadership + Security | Named role roster and access test | TODO |
| Reassignment authorization and dual review, if required | Management + Security | Approved workflow | TODO |
| User notices and delivery channels | Product + Privacy/Legal | Approved templates and delivery evidence | TODO |
| Retention of case evidence/audit records | Privacy/Legal | Approved retention schedule | TODO |
| Exercise of a disputed/recycled-number case | Support + Security | Dated drill or real redacted case evidence | TODO |

Until these rows are approved and evidenced, P-26 must remain **IMPLEMENTED — OPERATIONS/POLICY SIGNOFF REQUIRED** rather than COMPLETE.
