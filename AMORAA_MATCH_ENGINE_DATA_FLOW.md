# AMORAA — Match Engine Data Flow & Technical Trace

**Project:** AMORAA Dating Application  
**Repository:** `D:\Projects\amora_ai`  
**Document:** Match Engine Complete Data Flow Architecture  
**Mode:** Strictly Read-Only Audit Trace

---

## 1. System Architecture Diagram

```mermaid
graph TD
    subgraph Client["Flutter Client (Mobile / Web)"]
        UI_DISCOVER["Discover Tab<br/>(BrowseGridScreen)"]
        UI_MATCHES["Matches Tab<br/>(MatchesScreen)"]
        UI_CHATS["Chats Tab<br/>(ChatListScreen)"]
        
        CTRL_DISCOVER["DiscoverActionController<br/>(State Management)"]
        SVC_DISCOVER["DiscoverApiService"]
        SVC_P2["PhaseTwoApiService"]
        REPO_CHAT["ChatRepository"]
        
        UI_DISCOVER --> CTRL_DISCOVER
        CTRL_DISCOVER --> SVC_DISCOVER
        UI_MATCHES --> SVC_P2
        UI_CHATS --> REPO_CHAT
    end

    subgraph API["Node.js / Express API Layer"]
        AUTH_MW["requireAuth Middleware<br/>(JWT Verification)"]
        VAL_MW["validateRequest Middleware<br/>(express-validator)"]
        RATE_MW["discoverSwipeLimiter"]
        
        ROUTE_FEED["GET /api/discover/feed"]
        ROUTE_AI["GET /api/discover/ai-matches"]
        ROUTE_SWIPE["POST /api/discover/swipe"]
        ROUTE_REWIND["POST /api/discover/rewind"]
        ROUTE_MATCHES["GET /api/matches"]
        
        CTRL_DISC["discoverController.getFeed"]
        CTRL_SWIPE["discoverController.swipe"]
        CTRL_REWIND["discoverController.rewind"]
        CTRL_MATCH["matchController.list"]
    end

    subgraph Services["Backend Domain Services"]
        POLICY["discoverEligibilityPolicy<br/>(reciprocal clauses & completion)"]
        PREF_SVC["discoverPreferenceService<br/>(saved filters & defaults)"]
        GEO["geoDistance<br/>(Haversine & Bounding Box)"]
        SCORING["compatibilityScoringService<br/>(8-factor SQL & JS scoring)"]
        AI_PROV["aiMatchProvider<br/>(LOCAL deterministic re-ranker)"]
        CURSOR["recommendationCursorService<br/>(HMAC-SHA256 Keyset Cursor)"]
        ACCESS["accessControlService<br/>(Block & active checks)"]
        CHAT_SVC["conversationAccessService<br/>(Direct chat provisioning)"]
        NOTIF["notificationService<br/>(In-app notifications)"]
        SOCKET["realtimeHub<br/>(Socket.IO events)"]
    end

    subgraph Database["MySQL 8.0 / MariaDB"]
        TBL_USERS["Users"]
        TBL_PROFILES["OnboardingProfiles"]
        TBL_ACTIONS["DiscoverActions"]
        TBL_MATCHES["Matches"]
        TBL_BLOCKS["Blocks"]
        TBL_CONV["Conversations"]
        TBL_PARTS["ConversationParticipants"]
        TBL_PREFS["DiscoverFilterPreferences"]
    end

    %% Client to API Connections
    SVC_DISCOVER -->|GET /api/discover/feed| AUTH_MW
    SVC_DISCOVER -->|POST /api/discover/swipe| RATE_MW
    SVC_DISCOVER -->|POST /api/discover/rewind| AUTH_MW
    SVC_P2 -->|GET /api/discover/ai-matches| AUTH_MW
    SVC_P2 -->|GET /api/matches| AUTH_MW
    
    AUTH_MW --> VAL_MW
    RATE_MW --> VAL_MW
    
    VAL_MW --> ROUTE_FEED --> CTRL_DISC
    VAL_MW --> ROUTE_AI --> CTRL_DISC
    VAL_MW --> ROUTE_SWIPE --> CTRL_SWIPE
    VAL_MW --> ROUTE_REWIND --> CTRL_REWIND
    VAL_MW --> ROUTE_MATCHES --> CTRL_MATCH

    %% Controller to Services
    CTRL_DISC --> POLICY
    CTRL_DISC --> PREF_SVC
    CTRL_DISC --> GEO
    CTRL_DISC --> SCORING
    CTRL_DISC --> CURSOR
    CTRL_DISC --> AI_PROV

    CTRL_SWIPE --> ACCESS
    CTRL_SWIPE --> CHAT_SVC
    CTRL_SWIPE --> NOTIF
    CTRL_SWIPE --> SOCKET

    %% Services to Database
    POLICY --> TBL_PROFILES
    PREF_SVC --> TBL_PREFS
    GEO --> TBL_PROFILES
    SCORING --> TBL_PROFILES
    ACCESS --> TBL_BLOCKS
    CTRL_SWIPE --> TBL_ACTIONS
    CTRL_SWIPE --> TBL_MATCHES
    CHAT_SVC --> TBL_CONV
    CHAT_SVC --> TBL_PARTS
    CTRL_DISC --> TBL_USERS
    CTRL_MATCH --> TBL_MATCHES
```

---

## 2. Flutter-to-Backend Request Flow

### 2.1 Standard Discover Feed Request Flow
1. **Trigger:** `BrowseGridScreen` mounts or user exhausts available card stack.
   - Code location: [`lib/features/discover/presentation/browse_grid_screen.dart:237`](file:///d:/Projects/amora_ai/lib/features/discover/presentation/browse_grid_screen.dart#L237)
2. **Client API Call:**
   - Invokes `DiscoverApiService.getFeed(cursor, limit: 10, communicationStyles, surface: 'recommended')`.
   - Attaches `Authorization: Bearer <amora_access_token>`.
3. **HTTP Transport:**
   - `GET /api/discover/feed?limit=10&cursor=<token>`
4. **Backend Route & Middleware:**
   - Middleware chain: `requireAuth` $\to$ `feedValidation()` $\to$ `validateRequest` $\to$ `discoverController.getFeed`.
   - File: [`Backend/src/routes/discoverRoutes.js:16-17`](file:///d:/Projects/amora_ai/Backend/src/routes/discoverRoutes.js#L16-L17)
5. **Response Payload:**
   - Returns `{ success: true, message: 'Discover feed retrieved.', data: { profiles: [...], pagination: { hasMore, nextCursor } } }`.
6. **Client Ingestion:**
   - `BrowseGridScreen` converts JSON to `DummyProfile` objects via `publicProfileFromJson()`.
   - Passes profile IDs into `DiscoverActionController` deck.

### 2.2 AI Matches Feed Request Flow
1. **Trigger:** User opens "Matches" tab in navigation shell.
   - Code location: [`lib/features/matches/presentation/matches_screen.dart:184-218`](file:///d:/Projects/amora_ai/lib/features/matches/presentation/matches_screen.dart#L184-L218)
2. **Client API Call:**
   - Invokes `PhaseTwoApiService.instance.aiRecommendations(cursor, limit: 10)`.
   - File: [`lib/core/api/phase_two_api_service.dart:113-140`](file:///d:/Projects/amora_ai/lib/core/api/phase_two_api_service.dart#L113-L140)
3. **HTTP Transport:**
   - `GET /api/discover/ai-matches?limit=10&cursor=<token>`
4. **Backend Route Execution:**
   - File: [`Backend/src/routes/discoverRoutes.js:18`](file:///d:/Projects/amora_ai/Backend/src/routes/discoverRoutes.js#L18)
   - Interceptor sets `req.aiMatches = true; req.query.surface = 'high_compatibility';` then calls `discoverController.getFeed`.
5. **Backend Processing:**
   - Queries bounded candidate window (up to 500 candidates via `aiCandidateWindow()`).
   - Executes `rankCandidates()` in [`aiMatchProvider.js:62`](file:///d:/Projects/amora_ai/Backend/src/services/aiMatchProvider.js#L62).
   - Generates deterministic `aiMatchScore`, `aiConfidence`, `aiHighlights`, and `aiReasons`.
6. **Client Ingestion:**
   - Converts recommendations to `MatchApiItem` list in `MatchesScreen`.

---

## 3. Recommendation Generation & Filtering Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as Flutter Client
    participant API as discoverController.getFeed
    participant Pref as discoverPreferenceService
    participant Policy as discoverEligibilityPolicy
    participant DB as MySQL (Users & Profiles)
    participant AI as aiMatchProvider (LOCAL)
    participant Cursor as recommendationCursorService

    User->>API: GET /api/discover/feed (or /ai-matches)
    API->>DB: Check viewer completed profile (requireCompleted)
    DB-->>API: Viewer profile row
    
    API->>Pref: Load effective filters (filtersFor)
    Pref-->>API: Merged preferences (age, distance, gender, etc.)
    
    alt Continuation Cursor Provided
        API->>Cursor: readCursor(cursor, context)
        Cursor-->>API: Verified ranking keys (lastScore, lastId)
    end
    
    API->>Policy: Generate SQL where clauses
    Note over API,Policy: Exclude: self, inactive, deleted,<br/>already swiped (DiscoverActions),<br/>existing Matches, two-way Blocks
    
    API->>DB: User.findAll with OnboardingProfile join<br/>(Calculates compatibilityScore & distance in SQL)
    DB-->>API: Candidate rows (limit + 1 or AI window)
    
    alt isAiMatches == true
        API->>AI: rankCandidates(viewer, candidates)
        AI-->>API: Re-ranked candidates with aiConfidence & reasons
        API->>Cursor: createCursor({ aiScore, confidence, id })
        Cursor-->>API: Next cursor string
    else Standard Feed
        API->>Cursor: createCursor({ score, id, distance })
        Cursor-->>API: Next cursor string
    end
    
    API-->>User: 200 OK { profiles, pagination: { nextCursor, hasMore } }
```

---

## 4. Filtering and Ranking Logic Details

### Step 1: SQL Pre-Filter Formulation
In [`discoverController.js:301-377`](file:///d:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L301-L377), Sequelize generates a single monolithic query with:
1. `User.id NOT IN (SELECT targetUserId FROM DiscoverActions WHERE actorUserId = viewer.id)`
2. `User.id NOT IN (SELECT otherUserId FROM Matches WHERE viewer is participant)`
3. `User.accountStatus = 'active'`
4. `NOT EXISTS (SELECT 1 FROM Blocks WHERE blocker = viewer AND blocked = candidate OR vice-versa)`
5. `OnboardingProfile.birthDate BETWEEN dateFor(maxAge+1) AND dateFor(minAge)`
6. `OnboardingProfile.gender IN (viewer.interestedIn)`
7. `viewer.gender IN (OnboardingProfile.interestedIn) OR OnboardingProfile.interestedIn IS NULL`
8. `OnboardingProfile.matchLatitude BETWEEN minLat AND maxLat` (if distance filter active)
9. Correlated reciprocal age check: `viewerAge BETWEEN candidate.minAge AND candidate.maxAge`
10. Correlated reciprocal distance check: `distance <= candidate.maxDistanceKm`

### Step 2: In-Query Compatibility Scoring
In [`compatibilityScoringService.js:153-199`](file:///d:/Projects/amora_ai/Backend/src/services/compatibilityScoringService.js#L153-L199):
- Scalar factors (`city`, `smoking`, `drinking`, `weed`, `communicationStyle`) evaluate exact equality in SQL `CASE` expressions.
- List factors (`interests`, `relationshipGoals`, `languages`) evaluate element overlap using `JSON_TABLE` (MySQL 8) or sequence tables (MariaDB 10.4).
- The final score is computed as:
  ```sql
  LEAST(100, GREATEST(0, ROUND(50 + (weightedAgreement) - ((availableWeight) / 2))))
  ```

### Step 3: Order and Pagination
- **Standard Feed:**
  ```sql
  ORDER BY compatibilityScore DESC, User.id ASC
  LIMIT 11
  ```
- **Near You Feed:**
  ```sql
  ORDER BY ROUND(distanceKm, 6) ASC, compatibilityScore DESC, User.id ASC
  LIMIT 11
  ```
- **AI Matches:**
  Query limit is set to `aiCandidateWindow` (default 500). In-memory JavaScript sorting:
  ```javascript
  candidates.sort((a, b) => b.aiMatchScore - a.aiMatchScore || b.aiConfidence - a.aiConfidence || a.id - b.id)
  ```

---

## 5. Like / Pass / Super Like Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor A as User A (Actor)
    actor B as User B (Target)
    participant API as discoverController.swipe
    participant DB as MySQL Database
    participant Notif as notificationService
    participant WS as realtimeHub (Socket.IO)

    A->>API: POST /api/discover/swipe { targetUserId: B, action: 'like' }
    
    API->>DB: Check target user active & completed onboarding
    DB-->>API: Target user valid
    API->>DB: areUsersBlocked(A, B)
    DB-->>API: Not blocked
    
    rect rgb(240, 248, 255)
        Note over API,DB: Database Transaction Start
        API->>DB: SELECT * FROM Users WHERE id IN (A, B) ORDER BY id ASC FOR UPDATE
        API->>DB: SELECT * FROM DiscoverActions WHERE actorUserId = A AND targetUserId = B FOR UPDATE
        API->>DB: UPSERT DiscoverAction (actor: A, target: B, action: 'like')
        
        API->>DB: SELECT * FROM DiscoverActions WHERE actorUserId = B AND targetUserId = A AND action IN ('like', 'superLike')
        
        alt Reciprocal Like Does NOT Exist
            API->>Notif: createNotification(target: B, type: 'new_like')
            API->>DB: COMMIT Transaction
            API-->>A: 200 OK { matched: false, liked: true }
        else Reciprocal Like DOES Exist
            API->>DB: userOneId = min(A, B), userTwoId = max(A, B)
            API->>DB: Match.findOrCreate({ userOneId, userTwoId })
            API->>DB: Conversation.findOrCreate(pairKey: "min:max")
            API->>DB: ConversationParticipants.bulkCreate([A, B])
            API->>DB: COMMIT Transaction
            
            Note over API,WS: Asynchronous Match Notifications
            API->>WS: emitConversationEvent(conversationId, 'conversation.updated')
            API->>Notif: createNotification(A, type: 'new_match')
            API->>Notif: createNotification(B, type: 'new_match')
            
            API-->>A: 200 OK { matched: true, matchId, conversationId, matchedProfile }
        end
    end
```

---

## 6. Mutual-Match Creation Flow

When a mutual match occurs during `swipe()`:
1. **Canonical ID Ordering:**
   - `userOneId = Math.min(Number(req.user.sub), targetUserId)`
   - `userTwoId = Math.max(Number(req.user.sub), targetUserId)`
   - File: [`Backend/src/controllers/discoverController.js:594-595`](file:///d:/Projects/amora_ai/Backend/src/controllers/discoverController.js#L594-L595)
2. **Match Entity Creation:**
   - Table: `Matches`
   - Fields: `userOneId`, `userTwoId`, `matchedAt: NOW()`.
   - Handled with `Match.findOrCreate` to guarantee idempotency.
3. **Direct Conversation Provisioning:**
   - Service: [`conversationAccessService.ensureDirectConversation(userOneId, userTwoId)`](file:///d:/Projects/amora_ai/Backend/src/services/conversationAccessService.js#L57-L83)
   - Generates deterministic unique `pairKey = "${userOneId}:${userTwoId}"`.
   - Inserts row in `Conversations` (`type = 'direct'`).
   - Inserts 2 rows in `ConversationParticipants` (`joinedAt: NOW()`).
4. **Realtime & Push Notification Fan-Out:**
   - Emits Socket.IO room broadcast: `conversation.updated`.
   - Creates in-app notifications in `Notifications` table with deduplication keys:
     - Actor: `match:${matchId}:${actorUserId}`
     - Target: `match:${matchId}:${targetUserId}`
5. **Client Redirection:**
   - Flutter `DiscoverActionController` receives `matched: true`.
   - Triggers `ChatRepository.instance.refreshConversations()`.
   - Shows match dialog / celebration card on top of the swipe deck.

---

## 7. AI Compatibility Flow (LOCAL Provider)

```mermaid
flowchart TD
    START["GET /api/discover/ai-matches"] --> CHECK_COMPLETE["requireCompleted (Onboarding Check)"]
    CHECK_COMPLETE --> LOAD_WINDOW["SQL Query: Load candidate window<br/>(aiCandidateWindow = 500)"]
    
    LOAD_WINDOW --> ITERATE["Iterate each Candidate Profile"]
    
    subgraph LocalProvider["aiMatchProvider.js (LOCAL Engine)"]
        ITERATE --> FACTOR_EVAL["Extract 8 Factors & Canonical Weights<br/>(Interests, Goals, Style, Lang, City, Smoke, Drink, Weed)"]
        FACTOR_EVAL --> CALC_SUPPORT["Calculate Evidence Support:<br/>support = 100 * sum(w_i * v_i) / 100"]
        FACTOR_EVAL --> CALC_COV["Calculate Coverage:<br/>coverage = 100 * availableWeight / 100"]
        
        CALC_SUPPORT & CALC_COV --> AI_CONF["aiConfidence = clamp(0.8*coverage + 0.2*support)"]
        AI_CONF --> CONF_LEVEL["aiConfidenceLevel:<br/>>=80: High | >=50: Medium | <50: Low"]
        
        CALC_COV --> AI_SCORE["aiMatchScore = clamp(baseScore + round((coverage - 50) * 0.08))"]
        AI_SCORE --> MATCH_LEVEL["aiMatchLevel:<br/>>=90: EXCELLENT | >=80: STRONG | >=70: GOOD..."]
        
        FACTOR_EVAL --> REASONS["Generate Template Reasons & Highlights<br/>(Max 3 positive evidence factors)"]
    end
    
    CONF_LEVEL & MATCH_LEVEL & REASONS --> SORT["Sort Candidates:<br/>1. aiMatchScore DESC<br/>2. aiConfidence DESC<br/>3. userId ASC"]
    
    SORT --> PAGINATE["Slice page (offset to limit 10)"]
    PAGINATE --> CREATE_CURS["createCursor({ aiScore, confidence, id })"]
    CREATE_CURS --> RESP["Return JSON to Flutter MatchesScreen"]
```

---

## 8. Database Interaction Flow

| Table Name | Operation in Match Engine | Transactional? | Locks Held | Notes |
| :--- | :--- | :---: | :---: | :--- |
| `Users` | `SELECT ... FOR UPDATE` | Yes (in `swipe`) | Row lock on actor and target IDs | Prevents deadlocks by enforcing `ORDER BY id ASC`. |
| `OnboardingProfiles` | `SELECT` (joined in `getFeed`) | No | None (Shared read) | Correlated subqueries evaluate JSON arrays. |
| `DiscoverActions` | `SELECT ... FOR UPDATE`, `UPSERT` | Yes (in `swipe`) | Row lock | Enforces one action per user pair via unique index. |
| `Matches` | `findOrCreate` | Yes (in `swipe`) | Table/Index lock on insert | Created only when reciprocal action found. |
| `Conversations` | `findOrCreate` | Yes (in `swipe`) | Table/Index lock on insert | Unique `pairKey` prevents duplicate chats. |
| `ConversationParticipants` | `bulkCreate` | Yes (in `swipe`) | Row locks on insert | Attaches both users to the conversation. |
| `Blocks` | `SELECT` (anti-join in `getFeed`) | No | None (Read) | Hides blocked candidates from discovery. |
| `DiscoverFilterPreferences`| `SELECT`, `UPSERT` | No (in `updateFilters`) | None | Stores user's custom filter settings. |
| `Notifications` | `create` | Yes (in `swipe`) | Row lock on insert | Deduplication keys prevent duplicate alerts. |
| `MatchingActionFailures` | `create` | No | None | Logs business rejections (self-swipe, blocked). |
