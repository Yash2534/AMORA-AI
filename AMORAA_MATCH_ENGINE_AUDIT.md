# AMORAA — Comprehensive Match Engine Technical Audit (READ-ONLY)

**Project:** AMORAA Dating Application  
**Repository:** `D:\Projects\amora_ai`  
**Audit Date:** November 2026  
**Audit Scope:** Full repository code audit across Flutter frontend, Node.js/Express backend, and MySQL/Sequelize schema.  
**Mode:** Strictly Read-Only (no code, configuration, or database mutations performed).

---

## 1. Executive Summary

A comprehensive architectural, algorithmic, database, and security audit of the AMORAA Match Engine was conducted across the Flutter mobile application, Node.js backend services, and MySQL database schema.

### Key Conclusions:
1. **The Match Engine is 100% Deterministic and Rule-Based:** Despite prominent UI labels such as *"AI Matches"*, *"AI Confidence"*, and *"AI Insights"*, AMORAA has **no server-side LLM, no generative AI, no OpenAI/Gemini/Anthropic integration, no embeddings, and no vector database**. All match scoring, confidence metrics, and compatibility explanations are generated through deterministic mathematical formulas and hardcoded text templates (`LOCAL` provider in [`Backend/src/services/aiMatchProvider.js`](file:///d:/Projects/amora_ai/Backend/src/services/aiMatchProvider.js#L1-L67)).
2. **Scoring Formula Verified:** The engine computes an 8-factor weighted compatibility score totaling 100 points: Interests (35%), Relationship Goals (25%), Communication Style (10%), Languages (10%), City (5%), Smoking (5%), Drinking (5%), Weed (5%). When data is incomplete, the engine uses a coverage-weighted regression to a neutral baseline of 50%.
3. **Hard Filter vs. Action Parity Discrepancy (CRITICAL P0):** While `GET /api/discover/feed` and `GET /api/discover/ai-matches` apply rigorous eligibility rules (age bounds, gender preferences, reciprocal preferences, geographic bounding boxes, and activity status), the action endpoint `POST /api/discover/swipe` only verifies that the target account is active, completed onboarding, and not blocked. It **does not verify** that the target matches the actor's or target's age, gender, or location preferences. A user can directly swipe on any arbitrary user ID via the API and successfully create a match.
4. **Exact Distance Leak via Pagination Cursor (HIGH P1):** While the public profile serialization coarsens distances to multiples of 5 km for privacy, the HMAC-signed pagination cursor in `surface=near_you` embeds exact 6-decimal-place floating-point distances (`ROUND(distanceSql, 6)`, down to millimeter precision). Because the cursor is merely base64url-encoded JSON with an HMAC signature, any client can decode the cursor payload and extract the exact distance to candidate profiles.
5. **Reported Users Not Excluded (HIGH P1):** In [`Backend/src/services/discoverEligibilityPolicy.js`](file:///d:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L6), `report` is explicitly listed under `NON_EXCLUDING_RELATIONSHIPS`. Reporting a profile does not exclude that user from the reporter's feed or action paths unless the user also performs an explicit block.
6. **Rewind Match Inconsistency & Lack of Rate Limiting (HIGH P1):** The `POST /api/discover/rewind` endpoint deletes the user's latest `DiscoverAction` row. If that action triggered a mutual match, the `Match` and `Conversation` rows remain intact in the database, but the `DiscoverAction` is deleted. Furthermore, `POST /api/discover/rewind` lacks rate limiting, allowing unlimited automated rewinds.
7. **Performance Bottleneck at Scale (MEDIUM P2):** The SQL score calculation in [`Backend/src/services/compatibilityScoringService.js`](file:///d:/Projects/amora_ai/Backend/src/services/compatibilityScoringService.js#L153-L199) executes 6 correlated JSON table subqueries and trigonometric Haversine distance calculations per candidate row. Under large user counts (10,000+), un-indexed correlated JSON subqueries will lead to significant database query latencies.

---

## 2. Complete Match Engine Architecture

### 2.1 Component Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER CLIENT                                  │
│                                                                        │
│  [MainShell] (IndexedStack)                                            │
│    ├── Tab 0 (Discover): BrowseGridScreen                              │
│    │     └── DiscoverActionController ──► DiscoverApiService          │
│    ├── Tab 1 (Chats): ChatListScreen ──► ChatRepository                │
│    ├── Tab 2 (Matches): MatchesScreen ──► PhaseTwoApiService           │
│    └── Auxiliary: WhyWeMatchedScreen, AiIcebreakersScreen              │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │ HTTPS (JWT Bearer Token)
┌────────────────────────────────────▼───────────────────────────────────┐
│                        NODE.JS / EXPRESS BACKEND                       │
│                                                                        │
│  Routes:                                                               │
│    ├── /api/discover/feed          ──► discoverController.getFeed      │
│    ├── /api/discover/ai-matches    ──► discoverController.getFeed (AI) │
│    ├── /api/discover/swipe         ──► discoverController.swipe        │
│    ├── /api/discover/rewind        ──► discoverController.rewind       │
│    ├── /api/matches                ──► matchController.list            │
│    └── /api/matches/:matchId       ──► matchController.detail / remove │
│                                                                        │
│  Domain Services:                                                      │
│    ├── matchEngineService (delegates to compatibilityScoringService)   │
│    ├── aiMatchProvider (LOCAL deterministic heuristics)                │
│    ├── discoverEligibilityPolicy (SQL clauses & completion checks)     │
│    ├── discoverPreferenceService (saved filters & defaults)            │
│    ├── geoDistance (Haversine distance & bounding box)                 │
│    ├── recommendationCursorService (HMAC-SHA256 cursor pagination)     │
│    └── conversationAccessService (direct chat provisioning)            │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │ Sequelize ORM (Connection Pool)
┌────────────────────────────────────▼───────────────────────────────────┐
│                        MYSQL 8.0 / MARIADB                             │
│                                                                        │
│  Key Tables:                                                           │
│    ├── Users (accountStatus, identityVerifiedAt, lastActiveAt)         │
│    ├── OnboardingProfiles (birthDate, gender, interestedIn, JSON data) │
│    ├── DiscoverActions (actorUserId, targetUserId, action ENUM)        │
│    ├── Matches (userOneId, userTwoId, matchedAt)                       │
│    ├── DiscoverFilterPreferences (minAge, maxAge, maxDistanceKm, etc.) │
│    ├── Blocks (blockerUserId, blockedUserId)                           │
│    └── Conversations / ConversationParticipants (pairKey, direct chat) │
└────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Flutter Presentation & State Management Layer

1. **Persistent Navigation Shell:**
   - **File:** [`lib/core/navigation/main_shell.dart`](file:///d:/Projects/amora_ai/lib/core/navigation/main_shell.dart#L17-L121)
   - Manages tabs using an `IndexedStack` to preserve state, scroll position, and loaded decks across navigation.
   - **Tab 0 (`AmoraNavTab.discover`):** Hosts [`BrowseGridScreen`](file:///d:/Projects/amora_ai/lib/features/discover/presentation/browse_grid_screen.dart#L58-L78).
   - **Tab 1 (`AmoraNavTab.chats`):** Hosts [`ChatListScreen`](file:///d:/Projects/amora_ai/lib/features/chat/presentation/chat_list_screen.dart#L28-L50), which displays active conversations (created when mutual matches occur).
   - **Tab 2 (`AmoraNavTab.matches`):** Hosts [`MatchesScreen`](file:///d:/Projects/amora_ai/lib/features/matches/presentation/matches_screen.dart#L31-L53), which displays the "Best Matches" / "AI Matches" recommendation feed.

2. **Discover Feed Screen:**
   - **File:** [`lib/features/discover/presentation/browse_grid_screen.dart`](file:///d:/Projects/amora_ai/lib/features/discover/presentation/browse_grid_screen.dart#L58-L400)
   - Uses [`DiscoverActionController`](file:///d:/Projects/amora_ai/lib/features/discover/presentation/discover_action_controller.dart#L25-L192) to orchestrate swipe deck animations and API calls.
   - Calls [`DiscoverApiService.getFeed()`](file:///d:/Projects/amora_ai/lib/features/discover/data/discover_api_service.dart#L114-L155) with cursor pagination.
   - Provides client-side instant quick filters (`_QuickFilter` chips: Verified, Active, Nearby, Most Compatible, Music Lovers, Travel, Marriage, Coffee Dates) evaluated in-memory on line 352-383.

3. **Discover Action Controller:**
   - **File:** [`lib/features/discover/presentation/discover_action_controller.dart`](file:///d:/Projects/amora_ai/lib/features/discover/presentation/discover_action_controller.dart#L25-L192)
   - State management: `ChangeNotifier`.
   - Methods: `passProfile()`, `likeProfile()`, `superLikeProfile()`, `rewindProfile()`.
   - On mutual match (`responseData.matched == true`), extracts `matchId`, `conversationId`, triggers [`ChatRepository.instance.refreshConversations()`](file:///d:/Projects/amora_ai/lib/features/chat/data/chat_repository.dart#L258-L278), and exposes `matchedProfile` to present match overlays.

4. **AI Matches Screen:**
   - **File:** [`lib/features/matches/presentation/matches_screen.dart`](file:///d:/Projects/amora_ai/lib/features/matches/presentation/matches_screen.dart#L31-L218)
   - **Critical Architecture Finding:** While labeled "Matches" in the bottom navigation, this screen does **not** query mutual matches (`/api/matches`). It queries [`PhaseTwoApiService.aiRecommendations()`](file:///d:/Projects/amora_ai/lib/core/api/phase_two_api_service.dart#L113-L140) which calls `GET /api/discover/ai-matches`.
   - Displays unswiped, high-compatibility recommendation candidates. Users can bulk-select or individually like profiles from this grid.

5. **Why We Matched Screen:**
   - **File:** [`lib/features/match/presentation/why_we_matched_screen.dart`](file:///d:/Projects/amora_ai/lib/features/match/presentation/why_we_matched_screen.dart#L14-L148)
   - Displays factor breakdown badges and compatibility reasons received from the public profile object (`compatibilityReasons`).

6. **AI Icebreakers Screen:**
   - **File:** [`lib/features/ai_coach/presentation/ai_icebreakers_screen.dart`](file:///d:/Projects/amora_ai/lib/features/ai_coach/presentation/ai_icebreakers_screen.dart#L14-L163)
   - Explicit subtitle: *"Created on-device from visible profile details."*
   - Generates starters using deterministic string templates parameterized by first name, interest, and selected tone ('Thoughtful', 'Warm', 'Curious', 'Playful').

---

## 3. The Actual Matching Algorithm

### 3.1 Algorithm Category
The AMORAA match engine is **entirely rule-based and weighted-deterministic**. It does not employ neural networks, latent semantic analysis, or machine learning models.

### 3.2 Matching Factors and Canonical Weights
Defined in [`Backend/src/services/compatibilityScoringService.js`](file:///d:/Projects/amora_ai/Backend/src/services/compatibilityScoringService.js#L3-L15):

| Factor Key | Factor Type | Weight ($w_i$) | Max Items | Comparison Method | Availability Condition |
| :--- | :--- | :---: | :---: | :--- | :--- |
| `interests` | List | **35** | 20 | Jaccard-like list overlap ratio | Both users have $\ge 1$ non-empty, non-neutral interest |
| `relationshipGoals` | List | **25** | 30 | Jaccard-like list overlap ratio | Both users have $\ge 1$ relationship goal |
| `communicationStyle` | Scalar | **10** | N/A | Exact string match | Both users have non-null, valid style |
| `languages` | List | **10** | 30 | Jaccard-like list overlap ratio | Both users have $\ge 1$ language |
| `city` | Scalar | **5** | N/A | Exact case-insensitive match | Both users have non-empty city |
| `smoking` | Scalar | **5** | N/A | Exact case-insensitive match | Both users have non-empty, non-"prefer not to say" |
| `drinking` | Scalar | **5** | N/A | Exact case-insensitive match | Both users have non-empty, non-"prefer not to say" |
| `weed` | Scalar | **5** | N/A | Exact case-insensitive match | Both users have non-empty, non-"prefer not to say" |
| **Total Weight ($W$)** | | **100** | | | |

### 3.3 Exact Mathematical Scoring Formula

Let each factor $i \in \{1, \dots, 8\}$ have:
- Weight $w_i$ such that $\sum_{i=1}^8 w_i = 100$
- Availability flag $a_i \in \{0, 1\}$ (where $a_i = 1$ if and only if both profiles have usable data for factor $i$)
- Agreement value $v_i \in [0, 1]$

#### 1. Agreement Calculation ($v_i$):
- **Scalar Factors** (`communicationStyle`, `city`, `smoking`, `drinking`, `weed`):
  $$v_i = \begin{cases} 1 & \text{if } \text{normalized}(candidate_i) = \text{normalized}(viewer_i) \\ 0 & \text{otherwise} \end{cases}$$
- **List Factors** (`interests`, `relationshipGoals`, `languages`):
  Let $L_{\text{viewer}}$ and $L_{\text{candidate}}$ be the deduplicated, normalized sets of values (excluding empty strings and `"prefer not to say"`).
  $$v_i = \begin{cases} \frac{|L_{\text{viewer}} \cap L_{\text{candidate}}|}{\max(|L_{\text{viewer}}|, |L_{\text{candidate}}|)} & \text{if } a_i = 1 \\ 0 & \text{if } a_i = 0 \end{cases}$$

#### 2. Weight Aggregations:
- **Available Weight ($A$):**
  $$A = \sum_{i=1}^8 (w_i \cdot a_i)$$
- **Weighted Agreement ($S$):**
  $$S = \sum_{i=1}^8 (w_i \cdot v_i)$$
- **Raw Score ($\text{rawScore}$):**
  $$\text{rawScore} = \begin{cases} \frac{S}{A} \times 100 & \text{if } A > 0 \\ 50 & \text{if } A = 0 \end{cases}$$
- **Coverage Fraction ($C$):**
  $$C = \frac{A}{100}$$

#### 3. Final Compatibility Score:
The formula applies regression to a neutral baseline of 50 when data is missing:
$$\text{compatibilityScore} = \text{clamp}\left(50 + (\text{rawScore} - 50) \times C, \, 0, \, 100\right)$$

Notice the exact algebraic equivalence implemented in JavaScript and SQL:
$$50 + (\text{rawScore} - 50) \times C = 50 + \left(\frac{S}{A} \times 100 - 50\right) \times \frac{A}{100} = 50 + S - \frac{A}{2}$$

In [`Backend/src/services/compatibilityScoringService.js`](file:///d:/Projects/amora_ai/Backend/src/services/compatibilityScoringService.js#L197), this is executed in SQL as:
```sql
LEAST(100, GREATEST(0, ROUND(50 + (weightedAgreement) - ((availableWeight) / 2))))
```

### 3.4 AI Match Score Adjustment & Confidence
In [`Backend/src/services/aiMatchProvider.js`](file:///d:/Projects/amora_ai/Backend/src/services/aiMatchProvider.js#L41-L59), the `LOCAL` provider computes:
1. **AI Match Score:**
   $$\text{aiMatchScore} = \text{clamp}\left(\text{baseScore} + \text{round}((\text{coverage} - 50) \times 0.08)\right)$$
   *Note: This adjusts the compatibility score by at most $\pm 4$ points based on profile completeness.*
2. **AI Confidence Index:**
   $$\text{aiConfidence} = \text{clamp}(0.8 \times \text{coverage} + 0.2 \times \text{support})$$
   where $\text{support} = \frac{100 \times \sum (w_i \cdot v_i)}{100} = S$.
   - Confidence Level: $\ge 80 \implies \text{"High"}$; $\ge 50 \implies \text{"Medium"}$; $< 50 \implies \text{"Low"}$.

### 3.5 Fallbacks and Defaults
- If a candidate or viewer has not filled out a factor, $a_i = 0$. The factor is excluded from $A$, reducing overall coverage.
- If no comparable data exists ($A = 0$), the score defaults to **50%**.
- Scores are 100% deterministic: given the same viewer and candidate profiles, the score is identical on every request.

---

## 4. Discover Eligibility, Hard Filters, and Candidate Selection

The candidate selection query in [`discoverController.js`](file:///d:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L301-L409) enforces the following layers:

### 4.1 Base Eligibility Rules (Hard Exclusions)
1. **Self-Exclusion:** `User.id != viewer.id`.
2. **Account Status:** `User.accountStatus = 'active'`. Deactivated and deleted accounts are excluded.
3. **Completed Onboarding:** `User.id` joined to `OnboardingProfiles` with `onboardingCompleted = true` and `stage = 'complete'`.
4. **Mandatory Profile Elements:** Enforced via `profileCompletionSqlClauses` ([`discoverEligibilityPolicy.js:215-236`](file:///d:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L215-L236)):
   - Gender must be in `['male', 'female', 'other']`.
   - City must not be empty.
   - At least 1 valid `interestedIn` item.
   - At least 1 valid `relationshipGoals` item.
   - At least 2 uploaded photos.
5. **Two-Way Block Exclusion:** Anti-join subquery via `notBlockedUserSql` checks that neither user has blocked the other in `Blocks` table.
6. **Prior Action Exclusion:** Candidate must not exist in `DiscoverActions` where `actorUserId = viewer.id` with `action IN ('pass', 'like', 'superLike')`.
7. **Existing Match Exclusion:** Candidate must not exist in `Matches` table with viewer.

### 4.2 Gender and Reciprocal Preference Compatibility
- **Viewer Gender Preference:** Candidate `gender` must match viewer's `interestedIn` array. If viewer's preference contains universal tokens (`'everyone'`, `'all'`, `'any'`, `'both'`), candidate gender filter is bypassed.
- **Candidate Reciprocal Preference:** Candidate's `interestedIn` must contain viewer's gender or universal tokens. **Exception:** In [`discoverEligibilityPolicy.js:205-207`](file:///d:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L205-L207), if the candidate has `null` or empty `interestedIn`, the candidate is explicitly allowed. Reciprocity is therefore soft/one-sided when candidate preferences are unset.

### 4.3 Age and Reciprocal Age Filters
- **Viewer Age Preference:** Candidate birth date must fall within viewer's `[minAge, maxAge]` preference.
- **Candidate Reciprocal Age Preference:** Viewer's age must fall within candidate's saved `[minAge, maxAge]` preferences from `DiscoverFilterPreferences` ([`discoverEligibilityPolicy.js:120`](file:///d:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L120)).

### 4.4 Geographic Distance Filtering
- Coordinate storage: `OnboardingProfiles.matchLatitude` and `matchLongitude` (DECIMAL 9,6).
- If viewer has valid coordinates:
  1. SQL Bounding Box pre-filter (`distanceBoundingBox` in [`geoDistance.js:38-74`](file:///d:/Projects/amora_ai/Backend/src/utils/geoDistance.js#L38-L74)) restricts candidates to minimum/maximum latitude and longitude ranges.
  2. Haversine distance expression (`sqlDistanceExpression`) computes spherical distance in kilometers:
     $$\text{distance} \le \min(\text{viewerMaxDistanceKm}, \, \text{candidateMaxDistanceKm})$$
  3. If viewer coordinates are missing and surface is `near_you`, request fails with 409 `LOCATION_REQUIRED`. On standard feed, distance filtering is omitted if viewer coordinates are unavailable.

---

## 5. Likes, Passes, Matches, and Exclusions Lifecycle

### 5.1 The Interaction Lifecycle

```
User A swipes "like" on User B
  │
  ├─► POST /api/discover/swipe { targetUserId: B, action: 'like' }
  │     │
  │     ├─► Transaction Start (locks User A and User B rows ORDER BY id ASC)
  │     ├─► Check DiscoverActions: Actor=A, Target=B
  │     ├─► Upsert DiscoverAction (Actor=A, Target=B, action='like')
  │     │
  │     ├─► Check Reciprocal DiscoverAction: Actor=B, Target=A, action IN ('like', 'superLike')
  │     │
  │     ├── [Reciprocal NOT FOUND]:
  │     │     ├─► Create Notification for User B (type: 'new_like')
  │     │     ├─► Commit Transaction
  │     │     └─► Return { matched: false, liked: true }
  │     │
  │     └── [Reciprocal FOUND]:
  │           ├─► userOneId = min(A, B), userTwoId = max(A, B)
  │           ├─► Match.findOrCreate({ userOneId, userTwoId })
  │           ├─► ensureDirectConversation(userOneId, userTwoId)
  │           │     └─► Conversation.findOrCreate(pairKey: "min:max")
  │           │     └─► ConversationParticipants.bulkCreate([A, B])
  │           ├─► Commit Transaction
  │           ├─► Emit WebSocket event 'conversation.updated'
  │           ├─► Create Notifications for BOTH User A and User B (type: 'new_match')
  │           └─► Return { matched: true, matchId, conversationId, matchedProfile }
```

### 5.2 Mutual Like Trace
- **When User A likes User B:**
  1. `DiscoverActions` records `(actor: A, target: B, action: 'like')`.
  2. No reciprocal like from B exists.
  3. Notification created for User B: *"You received a like. Someone is interested in your profile."*
  4. Response: `{ matched: false, liked: true }`.
- **When User B subsequently likes User A:**
  1. `DiscoverActions` records `(actor: B, target: A, action: 'like')`.
  2. Reciprocal like `(actor: A, target: B, action: 'like')` is found.
  3. Canonical match row created in `Matches`: `userOneId = min(A, B)`, `userTwoId = max(A, B)`.
  4. Direct conversation created in `Conversations` with unique `pairKey = "${min}:${max}"` and participants mapped.
  5. Realtime Socket.IO event `conversation.updated` emitted to room `conversation:${id}`.
  6. Notifications created for both users: *"It's a match. You and [Name] matched."*
  7. Flutter `DiscoverActionController` receives `{ matched: true, conversationId: ... }` and invokes `ChatRepository.instance.refreshConversations()`.
  8. The match appears in User A and User B's **Chats tab**.

### 5.3 Duplicate Prevention and Concurrency
- `DiscoverActions` has a unique constraint index on `['actorUserId', 'targetUserId']` ([`DiscoverAction.js:2`](file:///d:/Projects/amora_ai/Backend/src/models/DiscoverAction.js#L2)). Upsert ensures idempotency.
- `Matches` has a unique constraint index on `['userOneId', 'userTwoId']` ([`Match.js:2`](file:///d:/Projects/amora_ai/Backend/src/models/Match.js#L2)). Because IDs are always sorted (`min(A, B)`, `max(A, B)`), duplicate reverse-order rows are impossible.
- Race conditions during concurrent mutual swipes are handled by database transactions with explicit row-level locking: `User.findAll({ where: { id: participantIds }, order: [['id', 'ASC']], transaction, lock: transaction.LOCK.UPDATE })` ([`discoverController.js:558-563`](file:///d:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L558-L563)).

### 5.4 Super Likes and Roses
- **Super Like:** Supported in `DiscoverActions` with `action: 'superLike'`. Functions identically to a like in terms of match creation, but triggers notification type `new_super_like` (*"You received a Super Like"*).
- **Roses:** Handled separately via [`roseController.js:51-181`](file:///d:/Projects/amora_ai/Backend/src/controllers/roseController.js#L51-L181) and [`RoseTransactions`](file:///d:/Projects/amora_ai/Backend/src/models/RoseTransaction.js). **Architectural Guardrail:** Roses do **not** bypass the mutual match requirement for chat. Sending a Rose records a transaction and notifies the recipient, but cannot create a chat conversation unless a mutual match already exists (`const matchedConversationAllowed = await activeMatch(senderId, recipientId);`).

### 5.5 Rewind and Unmatch Lifecycle
- **Rewind (`POST /api/discover/rewind`):** Finds the actor's most recent `DiscoverAction` row and destroys it ([`discoverController.js:643`](file:///d:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L643)).
  - If a pass is rewound, the profile immediately becomes eligible to appear in the Discover feed again.
  - If a like that created a match is rewound, the `DiscoverAction` is deleted, but the `Match` and `Conversation` rows remain intact.
- **Unmatch (`DELETE /api/matches/:matchId`):**
  - Destroys the `Match` row.
  - Does **not** delete `DiscoverAction` rows. Both users still have previous action records, ensuring they do not reappear in each other's Discover feed.
  - Locks conversation: [`conversationAccessService.js:43`](file:///d:/Projects/amora_ai/Backend/src/services/conversationAccessService.js#L43) requires `activeMatch()`. Once the `Match` row is deleted, subsequent chat access attempts return 404 / access denied.

---

## 6. AI Match and Compatibility Analysis

| Assessment Dimension | Codebase Finding | Classification | Exact Citation |
| :--- | :--- | :--- | :--- |
| **AI Model / Provider** | Only `PROVIDER = 'LOCAL'` exists. No external AI SDKs (OpenAI, Gemini, Anthropic, Bedrock) are installed or imported. | **Not Implemented** | [`Backend/src/services/aiMatchProvider.js:5`](file:///d:/Projects/amora_ai/Backend/src/services/aiMatchProvider.js#L5), [`Backend/package.json`](file:///d:/Projects/amora_ai/Backend/package.json#L58-L74) |
| **Vector Embeddings / Semantic Search** | No vector embeddings, cosine similarity, or vector database (pgvector, Pinecone, Milvus) exist. | **Not Implemented** | Verified across all backend source files |
| **AI Compatibility Scoring** | Uses deterministic formula: `aiMatchScore = clamp(baseScore + round((coverage - 50) * 0.08))`. | **Rule-Based Only** | [`Backend/src/services/aiMatchProvider.js:58`](file:///d:/Projects/amora_ai/Backend/src/services/aiMatchProvider.js#L58) |
| **AI Confidence Metric** | Uses deterministic formula: `aiConfidence = clamp(0.8 * coverage + 0.2 * support)`. | **Rule-Based Only** | [`Backend/src/services/aiMatchProvider.js:46`](file:///d:/Projects/amora_ai/Backend/src/services/aiMatchProvider.js#L46) |
| **AI Recommendation Reasons** | Hardcoded switch/case string templates based on 8 factor values. | **Rule-Based Only** | [`Backend/src/services/aiMatchProvider.js:18-27`](file:///d:/Projects/amora_ai/Backend/src/services/aiMatchProvider.js#L18-L27) |
| **AI Icebreaker Suggestions** | Client-side string interpolation templates in Flutter: `'$firstName, I noticed you enjoy $interest...'`. | **Rule-Based Only** | [`lib/features/ai_coach/presentation/ai_icebreakers_screen.dart:143-163`](file:///d:/Projects/amora_ai/lib/features/ai_coach/presentation/ai_icebreakers_screen.dart#L143-L163) |
| **Client Labeling** | Frontend uses labels "AI Matches", "AI Confidence", "Best Matches", and "AI Openers". | **UI-Only Labeling** | [`lib/features/matches/presentation/matches_screen.dart:477`](file:///d:/Projects/amora_ai/lib/features/matches/presentation/matches_screen.dart#L477) |

---

## 7. Database Schema and Query Analysis

### 7.1 Match Engine Schema Entities

```
┌─────────────────────────────────┐           ┌─────────────────────────────────┐
│              Users              │           │       OnboardingProfiles        │
├─────────────────────────────────┤           ├─────────────────────────────────┤
│ id (PK, INT AUTO_INC)           │1         1│ id (PK, INT AUTO_INC)           │
│ name (VARCHAR)                  ├───────────┤ userId (FK, INT, UNIQUE)        │
│ email (VARCHAR, UNIQUE)         │           │ birthDate (DATEONLY)            │
│ phoneNumber (VARCHAR)           │           │ gender (VARCHAR)                │
│ accountStatus (ENUM: active,    │           │ interestedIn (JSON)             │
│   deactivated, deleted)         │           │ relationshipGoals (JSON)        │
│ lastActiveAt (DATETIME)         │           │ city (VARCHAR)                  │
│ identityVerifiedAt (DATETIME)   │           │ matchLatitude (DECIMAL 9,6)     │
└────────────────┬────────────────┘           │ matchLongitude (DECIMAL 9,6)    │
                 │                            │ interests (JSON)                │
                 │1                           │ communicationStyle (ENUM)       │
                 │                            │ smoking, drinking, weed (VARCHAR│
                 │                            │ stage (ENUM), completed (BOOL)  │
                 │                            └─────────────────────────────────┘
                 │
                 │*
┌────────────────┴────────────────┐           ┌─────────────────────────────────┐
│         DiscoverActions         │           │             Matches             │
├─────────────────────────────────┤           ├─────────────────────────────────┤
│ id (PK, INT AUTO_INC)           │           │ id (PK, INT AUTO_INC)           │
│ actorUserId (FK, INT)           │           │ userOneId (FK, INT)             │
│ targetUserId (FK, INT)          │           │ userTwoId (FK, INT)             │
│ action (ENUM: pass, like,       │           │ matchedAt (DATETIME)            │
│   superLike)                    │           │ UNIQUE(userOneId, userTwoId)    │
│ UNIQUE(actorUserId, targetUserId│           │ INDEX(userTwoId, userOneId)     │
└─────────────────────────────────┘           └─────────────────────────────────┘
```

### 7.2 Database Indexes Relevant to Matching
- `OnboardingProfiles`:
  - `['onboardingCompleted', 'birthDate', 'communicationStyle', 'userId']` (`onboarding_profiles_discover_eligibility`)
  - `['matchLatitude', 'matchLongitude', 'userId']` (`onboarding_profiles_match_location`)
  - `userId` (UNIQUE)
- `DiscoverActions`:
  - `['actorUserId', 'targetUserId']` (UNIQUE)
- `Matches`:
  - `['userOneId', 'userTwoId']` (UNIQUE)
  - `['userTwoId', 'userOneId']` (`matches_user_two_user_one`)
  - `['matchedAt', 'id']` (`matches_matched_at_id`)
- `Blocks`:
  - `['blockerUserId', 'blockedUserId']` (UNIQUE)
  - `['blockedUserId', 'blockerUserId']` (`blocks_blocked_blocker`)

### 7.3 Query Bottlenecks & N+1 Problems
In [`compatibilityScoringService.js:153-199`](file:///d:/Projects/amora_ai/Backend/src/services/compatibilityScoringService.js#L153-L199), the SQL score expression constructs multiple correlated subqueries that execute per candidate row:
- 2 correlated subqueries per JSON array factor (interests, relationship goals, languages) to compute total usable candidate count and shared viewer count.
- Correlated subqueries against `DiscoverFilterPreferences` to compute candidate reciprocal age and distance bounds.
- Haversine trigonometric functions (`COS`, `SIN`, `ACOS`, `RADIANS`).

**Performance Implication:** In MySQL 8.0 / MariaDB, correlated JSON subqueries cannot use B-tree indexes. For a candidate pool of 50,000 eligible profiles, the database must perform hundreds of thousands of JSON unpack/extract operations per feed request unless restricted by tight pre-filters (city, bounding box, verified status).

---

## 8. Security and Privacy Review

### 8.1 Findings Summary Table

| Finding ID | Title | Severity | Impact | Status |
| :---: | :--- | :---: | :--- | :--- |
| **SEC-01** | Action Endpoint Lacks Eligibility & Preference Verification | **CRITICAL** | IDOR / Filter Bypass: Any user can swipe on any arbitrary profile ID, bypassing age, gender, distance, and preference checks. | Verified in Code |
| **SEC-02** | Exact Distance Millimeter Precision Leak in Pagination Cursor | **HIGH** | Privacy: Next cursor embeds `distanceRank` rounded to 6 decimal places. Clients can decode cursor and obtain exact user distance. | Verified in Code |
| **SEC-03** | Reported Users Not Excluded from Discover Feed | **HIGH** | Safety / Harassment: Reporting a user does not suppress them from recommendations or actions. | Verified in Code |
| **SEC-04** | Rewind Endpoint Lacks Rate Limiting & Cooldown | **HIGH** | Abuse: Users can script rapid rewind cycles to cycle through candidates or stress database write locks. | Verified in Code |
| **SEC-05** | Memory Overhead on AI Matches Endpoint (`aiCandidateWindow`) | **MEDIUM** | Denial of Service / Memory Pressure: Fetches 500 full Sequelize model instances per request into Node.js heap. | Verified in Code |
| **SEC-06** | Coarse Distance Privacy Protection in Public Profile | **INFORMATIONAL** | Positive: `serializePublicProfile` rounds public distance to nearest 5 km (min 5 km) and strips raw lat/long coordinates. | Verified in Code |
| **SEC-07** | PII Sanitization in Public Profile | **INFORMATIONAL** | Positive: Phone numbers, email addresses, password hashes, and auth tokens are excluded from public profile serialization. | Verified in Code |

### 8.2 Detailed Security Findings

#### SEC-01 (CRITICAL): Action Endpoint Lacks Eligibility & Preference Verification
- **File:** [`Backend/src/controllers/discoverController.js:527-551`](file:///d:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L527-L551)
- **Vulnerability:** `POST /api/discover/swipe` accepts any `targetUserId`. It validates:
  1. `targetUserId !== req.user.sub`
  2. `target.accountStatus === 'active'`
  3. `target.OnboardingProfile.onboardingCompleted === true`
  4. `!areUsersBlocked(req.user.sub, targetUserId)`
- **Flaw:** It does **not** check:
  - Does the candidate match the viewer's `interestedIn` gender?
  - Does the viewer match the candidate's `interestedIn` gender?
  - Is the candidate within the viewer's age range?
  - Is the viewer within the candidate's age range?
  - Is the candidate within the distance radius?
- **Exploitation:** A rogue client can iterate through user IDs (`1, 2, 3...`) and swipe "like" on all users in the system, forcing matches with users who explicitly excluded them by age, gender, or location.

#### SEC-02 (HIGH): Exact Distance Millimeter Precision Leak in Pagination Cursor
- **Files:** [`Backend/src/controllers/discoverController.js:398, 507`](file:///d:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L398), [`Backend/src/services/recommendationCursorService.js:42-52`](file:///d:/Projects/amora_ai/Backend/src/services/recommendationCursorService.js#L42-L52)
- **Vulnerability:** In `surface=near_you`, the query includes `[literal(distanceRankSql), 'distanceRank']` where `distanceRankSql = ROUND(distanceSql, 6)`.
- Line 507 puts this value into the cursor:
  ```javascript
  keys: { distance: Number(lastSelected.user.OnboardingProfile.getDataValue('distanceRank')), ... }
  ```
- Line 50 creates an HMAC-SHA256 cursor whose payload is `Buffer.from(...).toString('base64url')`.
- **Flaw:** HMAC guarantees authenticity, not confidentiality. Anyone with the cursor can execute `atob(cursor.split('.')[0])` to read the JSON payload containing the exact float distance (e.g. `12.345678` km). An attacker with two or three sample points can trilaterate a user's exact physical home or work location down to a few meters.

#### SEC-03 (HIGH): Reported Users Not Excluded from Discover Feed
- **File:** [`Backend/src/services/discoverEligibilityPolicy.js:6`](file:///d:/Projects/amora_ai/Backend/src/services/discoverEligibilityPolicy.js#L6)
- **Vulnerability:** `const NON_EXCLUDING_RELATIONSHIPS = Object.freeze(['rose', 'save', 'report']);`.
- **Flaw:** Reporting a user creates a row in `Reports` for admin review, but does not add the candidate to the exclusion list in `getFeed`. A user who reports another user for harassment will continue seeing that harasser in their Discover feed until an administrator manually suspends the account or the user performs a separate Block action.

#### SEC-04 (HIGH): Rewind Endpoint Lacks Rate Limiting
- **Files:** [`Backend/src/routes/discoverRoutes.js:20`](file:///d:/Projects/amora_ai/Backend/src/routes/discoverRoutes.js#L20), [`Backend/src/controllers/discoverController.js:633-650`](file:///d:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L633-L650)
- **Vulnerability:** `router.post('/rewind', controller.rewind);` does not attach `discoverSwipeLimiter` or any rate limiter.
- **Flaw:** An automated bot can swipe and rewind continuously without triggering rate limits, potentially abusing transaction resources or repeatedly unmasking previously swiped profiles.

---

## 9. Performance, Quality, Fairness, and Scalability

### 9.1 Ranking Bias & Inactive User Suppression
- Standard Discover feed orders candidates by:
  `ORDER BY compatibilityScore DESC, id ASC`
- **Fairness Risk:** Users with higher compatibility scores (often users who selected standard common interests like "Music", "Coffee", "Travel") will always appear first for almost all viewers. New users or users with niche interests may be pushed to deep pages that viewers rarely reach.
- **Inactive Users:** Inactive users remain in the feed unless filtered out by the optional `onlineNow` filter. While `lastActiveAt` is recorded, standard ranking does not decay scores over time based on user inactivity. An inactive profile with 95% compatibility will permanently outrank an active user with 80% compatibility.

### 9.2 Scalability Projections

| Active User Base | Estimated Database Load | Scalability Assessment |
| :--- | :--- | :--- |
| **10,000 Users** | Moderate (~50–150ms query time) | Manageable with current B-tree indexes and small active candidate sets. |
| **100,000 Users** | High (~400–1,500ms query time) | Correlated JSON subqueries and trigonometric Haversine scans will degrade database throughput. Connection pool exhaustion possible under peak load. |
| **1,000,000 Users** | Critical (>3,000ms, timeout risk) | **Unviable without architectural changes.** Requires decoupling candidate filtering from scoring: pre-filtering candidates via Redis/Elasticsearch/spatial indexes followed by in-memory scoring. |

### 9.3 In-Memory Overhead of AI Matches
- In [`Backend/src/controllers/discoverController.js:407`](file:///d:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L407):
  ```javascript
  limit: isAiMatches ? aiCandidateWindow(process.env) : limit + 1
  ```
  `aiCandidateWindow` defaults to **500** (`scalability.js:35`).
- On every call to `/api/discover/ai-matches`, the backend pulls 500 complete User, OnboardingProfile, and Subscription Sequelize model instances into Node.js heap memory, runs JavaScript scoring on all 500, sorts them, and returns the top 10.
- With 100 concurrent requests, this instantiates 50,000 heavy Sequelize model instances simultaneously, risking Garbage Collection pauses and Node.js process Out-Of-Memory (OOM) crashes.

---

## 10. Implemented vs. Partially Implemented vs. Missing Features

| Feature / Capability | Status | Implementation Details |
| :--- | :---: | :--- |
| **8-Factor Compatibility Scoring** | **IMPLEMENTED** | Implemented identically in JS (`scoreCompatibility`) and SQL (`sqlCompatibilityExpressions`). |
| **Discover Feed Pagination** | **IMPLEMENTED** | Cursor-based keyset pagination with HMAC-SHA256 signature and context fingerprinting. |
| **Mutual Match Detection** | **IMPLEMENTED** | Transactional check on reciprocal like/superLike; creates Match and direct Conversation. |
| **Two-Way Block Exclusion** | **IMPLEMENTED** | Checked via `notBlockedUserSql` in feed and `areUsersBlocked` in swipe. |
| **Geographic Distance Filtering** | **IMPLEMENTED** | Bounding box pre-filter + Haversine spherical distance calculation. |
| **Coarse Distance Serialization** | **IMPLEMENTED** | Profile serialization rounds distance up to nearest 5 km (min 5 km). |
| **Rewind Previous Swipe** | **PARTIAL** | Deletes last action, but does not clean up Match/Conversation if swiped like resulted in match. |
| **Action Endpoint Eligibility Parity** | **PARTIAL** | Validates active status and blocks, but does not validate gender, age, or distance preferences. |
| **Reciprocal Preference Check** | **PARTIAL** | Reciprocal preference is checked, but empty/null candidate preferences are allowed through. |
| **Report-Based Feed Exclusion** | **MISSING** | Explicitly categorized as non-excluding; reports do not hide profiles. |
| **Server-Side AI / LLM Matching** | **MISSING** | No LLMs, embeddings, or ML models. Provider is hardcoded to `LOCAL` deterministic logic. |
| **Semantic / Embedding Search** | **MISSING** | No vector similarity or embedding models exist in the codebase. |
| **Activity-Based Score Decay** | **MISSING** | Inactive users retain full compatibility score indefinitely. |

---

## 11. Recommendations for Improvement

### Immediate Pre-Launch Fixes (P0 / P1)
1. **Enforce Eligibility at Action Time (P0):**
   - Refactor `POST /api/discover/swipe` to execute the exact same reciprocal eligibility checks (gender preference, age boundaries, geographic radius) as `getFeed`.
2. **Sanitize Cursor Distance Rank (P1):**
   - In [`discoverController.js:507`](file:///d:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L507), round `distanceRank` to coarse 5 km buckets before embedding it into pagination cursor keys, or encrypt the cursor payload with AES-GCM rather than plain base64url HMAC signing.
3. **Add Immediate Reporter Exclusion (P1):**
   - Move `report` from `NON_EXCLUDING_RELATIONSHIPS` to the feed exclusion query in `getFeed` so that reporting a user immediately hides them from the reporter's feed.
4. **Add Rate Limiting to Rewind (P1):**
   - Apply `discoverSwipeLimiter` or a dedicated `rewindLimiter` to `POST /api/discover/rewind` in [`discoverRoutes.js:20`](file:///d:/Projects/amora_ai/Backend/src/routes/discoverRoutes.js#L20).
5. **Harmonize Rewind with Matches (P1):**
   - If the action being rewound created a match, either disallow rewind or transactionally remove the associated `Match` row.

### Medium-Term Optimization (P2)
1. **Reduce AI Candidate Window:**
   - Lower default `AI_DISCOVERY_CANDIDATE_WINDOW` from 500 to 50–100, or perform the re-ranking in SQL to reduce Node.js memory pressure.
2. **Materialize Compatibility Factors:**
   - Pre-compute interest and preference bitmaps or pre-joined relational tables rather than executing correlated `JSON_TABLE` / sequence subqueries per row.
3. **Inactivity Score Decay:**
   - Incorporate `lastActiveAt` recency into the ranking sort order so that active users are surfaced ahead of abandoned accounts.

---

## 12. Questions Requiring Product-Owner Decisions

1. **AI Terminology & Regulatory Compliance:**
   - The application labels deterministic matching and template icebreakers as *"AI Matches"* and *"AI Confidence"*. Under emerging consumer protection and AI transparency frameworks (e.g., EU AI Act, FTC guidance, India DPDP Act), does AMORAA wish to retain "AI" branding for deterministic algorithms, or transition to transparent labeling such as *"Compatibility Matching"* and *"Smart Starters"*?
2. **Rewind Policy for Mutual Matches:**
   - Should a user be permitted to "Rewind" a like after it has already turned into a mutual match? If yes, should unmatching and archiving the conversation occur automatically?
3. **Report Action Behavior:**
   - When User A reports User B, should User B be immediately blocked and hidden from User A's feed, or should they remain visible until moderator action?
4. **Strict vs. Soft Reciprocal Preferences:**
   - If Candidate B has not specified an `interestedIn` gender preference, should Candidate B appear in User A's feed (current behavior), or should incomplete preferences be excluded from discovery?
5. **Default Verification Filter:**
   - `verifiedOnly` defaults to `true` in [`discoverPreferenceService.js:37`](file:///d:/Projects/amora_ai/Backend/src/services/discoverPreferenceService.js#L37) (though default table migration sets `false`). If enabled by default for new users at soft launch, will there be enough verified profiles in new geographic markets to prevent empty feeds?
