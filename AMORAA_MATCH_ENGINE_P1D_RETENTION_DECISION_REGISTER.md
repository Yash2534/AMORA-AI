# AMORAA MATCH ENGINE — PHASE 3 P1-D
# DATA LIFECYCLE & RETENTION DECISION REGISTER

**Date:** 2026-11-02  
**Branch:** `p0-safety-remediation`  
**Scope:** Data Retention, Anonymization, and Lifecycle Policies for Chat, Matches, and Trust & Safety Data  
**Author:** Senior Backend Security Engineer & Privacy Architect  
**Status:** Formal Engineering Decision Record

---

## 1. Context & Purpose

In dating and social discovery applications, chat and match data sits at the intersection of two conflicting regulatory and safety demands:
1. **Safety & Moderation Mandate:** Users who experience harassment, stalking, assault threats, fraud, or non-consensual sharing often unmatch or block the perpetrator immediately. If unmatching or blocking were to trigger immediate hard deletion of conversations and media, critical forensic evidence would be destroyed, leaving safety teams powerless and enabling bad actors to abuse with impunity.
2. **Privacy & Data Protection Mandate:** Data protection frameworks (GDPR Art. 17 Right to Erasure, Indian Digital Personal Data Protection Act 2023, California CCPA/CPRA) mandate that personal data must not be retained indefinitely once the purpose for processing ceases, subject to legitimate safety and legal exceptions.

This Decision Register records the exact architectural state of AMORAA data retention across all entities, formalizes product decisions, outlines legal dependencies, and provides actionable engineering recommendations for long-term lifecycle management.

---

## 2. Data Lifecycle & Retention Master Table

| Entity / Data Category | Current Implementation (As of P1-D) | Formalized Product Decision | Legal / Compliance Dependency | Engineering Recommendation (Future P2) |
|---|---|---|---|---|
| **Conversations** (`Conversations`, `ConversationParticipants`) | Preserved in MySQL indefinitely on unmatch and block; access dynamically revoked via `conversationAccessService`. | **Decision 4:** Retain conversation shell and participant records for moderation and audit history. | Legal review on maximum inactive retention period under DPDP Act / GDPR. | Archive conversations inactive for > 180 days to cold storage with cryptographic access logging. |
| **Messages (Text)** (`Messages`) | Preserved in MySQL table; user deletion sets `deletedAt` (soft-delete). Unmatch/Block leaves rows intact but inaccessible. | **Decision 4:** Never hard-delete messages upon unmatch or block. Retain for safety investigation. | GDPR Art. 17(3)(e) legal claims exception; retention schedule review. | Encrypt message bodies at rest with user-specific KMS keys; cold-tier after 1 year of inactivity. |
| **Message Media / Attachments** (`MessageMedia`, `/uploads/chat/`) | Media records preserved in DB; uploaded files remain on storage volume. Download endpoint requires active match. | **Decision 4:** Retain attachments to permit forensic review of abusive photos or illegal content. | Verification of child safety / CSAM reporting obligations and evidentiary standards. | Move files older than 90 days of inactive conversation to restricted cold S3/GCS bucket with signed URLs for admin review. |
| **Moderation Reports & Evidence** (`Reports`, `AdminReportCases`, `ReportEvidences`) | Created via `POST /api/reports`; persists reported user, reporter, reason, details, and chat snapshots. Never deleted on unmatch. | Retain permanently or until case resolution + statutory limitation period (typically 3–5 years). | Alignment with applicable statutes of limitations for criminal and civil harassment. | Implement automated case closure workflows with strict RBAC access logs for Trust & Safety operators. |
| **Blocks** (`Blocks`) | Retained permanently in `Blocks` table to ensure persistent mutual exclusion across Discover, Chat, and Profiles. | Permanent block retention to prevent re-encounter or re-matching. | Must survive profile re-activations and account reactivation attempts. | Maintain permanent cryptographic hashes of blocked pairs even if accounts undergo deletion. |
| **Notifications** (`Notifications`, `NotificationDeliveries`) | Soft-deleted (`deletedAt: new Date()`) on unmatch or block; push suppressed at delivery time. | Soft-deleted notifications hidden from client UI. | Ephemeral communication metadata retention. | Hard-purge soft-deleted notifications older than 30 days via scheduled batch job. |
| **Discover Actions & Swipes** (`DiscoverActions`) | Swipes retained in `DiscoverActions`. Rewind deletes the single action row within 15-minute window. | Retain actions to prevent repeat candidates in feed; rewind window strictly 15 minutes. | Consent validity under privacy law for recommendation history. | Partition `DiscoverActions` by year or quarter; purge pass actions older than 180 days if feed resets. |
| **Database Backups & Write-Ahead Logs** | Daily automated snapshots / binary logs. | Standard operational recovery retention (30 days rolling). | Backup lifecycle compliance under GDPR (ensuring soft-deleted records age out). | Enforce automated backup expiration at 30 days. |

---

## 3. Product Decisions Formalized in Phase 3

### Decision 4: No Hard Deletion on Unmatch or Block
- **Decision:** When a user unmatches or blocks another user, AMORAA shall NOT execute `DELETE FROM Conversations` or `DELETE FROM Messages`.
- **Rationale:** 
  1. A perpetrator should not be able to destroy evidence of harassment by quickly unmatching their victim.
  2. A victim who blocks a stalker must still be able to submit a safety report, and AMORAA Trust & Safety agents must have full access to message logs to evaluate the report.
  3. If law enforcement issues a lawful warrant or subpoena, AMORAA must be able to produce conversation transcripts where legally required.
- **Access Control Mechanism:** The conversation is made completely invisible and inaccessible to both participants through `conversationAccessService`. The endpoints `/api/conversations/:id`, `/api/conversations/:id/messages`, and WebSocket channels return `404 CONVERSATION_NOT_AVAILABLE`.

### Decision 5: Complete Real-Time Severance on Unmatch & Block
- **Decision:** Unmatching and blocking must immediately sever all active WebSocket connections for the pair and evict them from the conversation room.
- **Rationale:** Preventing lingering sockets from receiving typing events, read receipts, or message payloads in transit.

### Decision 6: Dual-Layer Notification Shield
- **Decision:** Push notifications must be authorized both at the moment of queuing and at the moment of dispatch.
- **Rationale:** Eliminates the race condition where a notification queued seconds before a block is delivered after the block, which constitutes harassment.

---

## 4. Legal & Regulatory Dependencies (Prior to Production Launch)

Before deploying automated data purge routines to production, the following legal determinations are required:

1. **Statutory Retention Under DPDP Act 2023 (India):**
   - Section 8(7) requires Data Fiduciaries to erase personal data upon withdrawal of consent or as soon as the specified purpose is fulfilled.
   - However, Section 8(8) permits retention for compliance with laws or prevention of offences.
   - *Legal Action:* AMORAA Legal Counsel must establish a formal retention window schedule (e.g., 90 days vs 180 days vs 3 years) for safety-exempted message logs.

2. **GDPR Article 17 vs 17(3)(e) (European Users):**
   - Under GDPR Art. 17(1), users have the right to request erasure ("right to be forgotten").
   - Under GDPR Art. 17(3)(e), retention is lawful where necessary for "the establishment, exercise or defence of legal claims."
   - *Legal Action:* AMORAA privacy policy must explicitly inform users that chat logs may be retained in cold storage for a limited period for trust, safety, and legal defense even after account closure or unmatching.

3. **Law Enforcement & Evidentiary Standards:**
   - Preservation format for chat transcripts (including cryptographic timestamps, IP addresses, and sender IDs) must meet standard evidentiary requirements.

---

## 5. Engineering Roadmap & Technical Recommendations (Phase 3 P2 & Beyond)

1. **Tiered Archival Pipeline (Cold Storage):**
   - Create an automated background job (outside web request cycles) that identifies conversations where both users have been inactive, unmatched, or blocked for $\ge 180$ days.
   - Compress and move conversation text and media references to an encrypted, access-logged archival store (e.g., Amazon S3 Glacier / Google Cloud Archive).
   - Drop the active rows from high-frequency OLTP tables (`Messages`, `MessageMedia`) to maintain lean index sizes and fast queries.

2. **Automated Notification Purge Job:**
   - Soft-deleted notifications (`deletedAt IS NOT NULL`) carry no evidentiary or safety value once older than 30 days.
   - Deploy a nightly batch job:
     ```sql
     DELETE FROM Notifications 
     WHERE deletedAt IS NOT NULL AND deletedAt < DATE_SUB(NOW(), INTERVAL 30 DAY);
     ```

3. **Dedicated Admin Audit Vault:**
   - Trust & Safety staff accessing severed conversation records via the Admin Panel must trigger an immutable audit log entry recording:
     - Admin ID, Target Conversation ID, Target User IDs, Reason / Report Ticket ID, Timestamp.
   - Prevents internal misuse or unauthorized employee snooping on private messages.

4. **Account Erasure Workflow (`DELETE /api/users/me`):**
   - When a user deletes their account:
     - PII (phone, email, real name, birth date, photos) is scrubbed or hashed.
     - Conversation messages sent by the user remain attributed to `[Deleted User]` to preserve readability for the conversation partner and safety audits.
     - Entire conversation is purged only when *both* participants have deleted their accounts and the 180-day safety retention hold has elapsed.

---

## 6. Verification & Safety Sign-Off

- **Audit Confirmation:** Code inspection confirms zero automated cron purge jobs currently delete conversations, messages, or media in the codebase.
- **Test Evidence:** Verified by Tests 50, 51, and 52 in `Backend/test/chat-access-severance.test.js`:
  - Test 50: Verified Block leaves `Conversation` and `Message` rows intact in MySQL.
  - Test 51: Verified Unmatch leaves `Conversation` and `Message` rows intact in MySQL.
  - Test 52: Verified no rogue cron jobs or automated scripts purge chat data without policy.

**Status:** Formalized & Approved for Phase 3 P1-D.
