# AMORAA Match Engine — Phase 3 P1-B
# Location & Distance Privacy Enforcement Report

**Milestone:** Phase 3 P1-B — Location & Distance Privacy Enforcement  
**Date:** 2026-11-02  
**Branch:** `p0-safety-remediation`  
**Target Files:**  
- `Backend/src/models/OnboardingProfile.js`  
- `Backend/src/utils/logger.js`  
- `Backend/src/services/discoverEligibilityPolicy.js`  
- `Backend/src/services/publicProfileService.js`  
- `Backend/test/location-privacy.test.js`  
**Verdict:** **PASS — P1-B COMPLETE**

---

## 1. Executive Summary

Phase 3 P1-B required a comprehensive privacy engineering review and enforcement audit of how geographic location and calculated distance data are collected, stored, processed, returned, and logged across the AMORAA Match Engine.

The guiding objective is:
> **A client must never receive another user's exact geographic coordinates or precise calculated distance unless a separately documented and explicitly approved product requirement legally and technically justifies it.**

Our audit revealed that:
1. Public profile serialization ([`serializePublicProfile`](file:///d:/Projects/amora_ai/Backend/src/services/publicProfileService.js#L29-L96)) already applies `coarseDistanceKm` (rounding to multiples of 5 km with a 5 km minimum floor), preventing exact distance leakage on public endpoints.
2. Recommendation cursors in P1-A encrypt ranking keys using AES-256-GCM AEAD, preventing client-side decryption of distance rank values.
3. However, `OnboardingProfile.prototype.toJSON` did not previously filter out `matchLatitude` and `matchLongitude`, presenting an accidental serialization exposure risk.
4. The backend DPDP logger ([`logger.js`](file:///d:/Projects/amora_ai/Backend/src/utils/logger.js)) lacked coordinate and distance keys in its redaction regex.
5. In `validateSwipeEligibility`, the internal failure object returned the precise unrounded floating-point distance and allowed distance.

All identified vulnerabilities were remediated with surgical, defense-in-depth protections. 82/82 unit, integration, and privacy regression tests are passing on the isolated local database schema (`amora_ai_test`).

---

## 2. Initial Audit Findings

### 2.1 Database Schema & Model Layer
- `OnboardingProfiles` stores `matchLatitude` and `matchLongitude` as `DECIMAL(9, 6)` (~0.1m precision) along with `locationUpdatedAt` (timestamp).
- Models `User`, `Match`, `DiscoverAction`, `Conversation`, `Message`, `Block`, `Report`, `MatchingActionFailure`, and `MatchRecommendationEvent` do **not** store GPS coordinates.
- Prior to P1-B, calling `profile.toJSON()` on an `OnboardingProfile` instance included `matchLatitude` and `matchLongitude` in the returned plain JavaScript object. While controllers manually constructed response payloads, any direct serialization (e.g. `res.json({ profile })` or uncaught error dumps) risked exposing coordinates.

### 2.2 API Response Layer
- **Discover Feed (`/api/discover/feed`):** Returns `profiles` serialized via `serializePublicProfile`. Coordinates are excluded. `distance` and `distanceKm` are coarsened to integers $\ge 5$ in steps of 5 km. `locationMatching` exposes only boolean metadata (`viewerLocationAvailable`, `distanceFilterActive`).
- **AI Matches (`/api/discover/ai-matches`):** Uses identical serialization; no coordinates or raw distances.
- **Near You (`/api/discover/feed?surface=near_you`):** Uses identical serialization.
- **Target Profile (`/api/profiles/:userId`):** Coordinates are excluded; `distance` and `distanceKm` are `null`.
- **Own Profile (`/api/me/profile`):** Returns `city`, `locationAvailable: boolean`, and `locationUpdatedAt: string`. Raw coordinates are omitted.
- **Location Management (`/api/me/location`):** `GET`, `PUT`, and `DELETE` return only `{ locationAvailable, locationUpdatedAt }`. Coordinates submitted in `PUT` are stored but never reflected back.

### 2.3 Diagnostic & Logging Layer
- The DPDP redaction logger ([`logger.js`](file:///d:/Projects/amora_ai/Backend/src/utils/logger.js)) masked passwords, tokens, Aadhaar, and emails, but its `SENSITIVE_KEY` pattern did not include `matchLatitude`, `matchLongitude`, `latitude`, `longitude`, `coordinates`, or `distanceKmPrecise`.
- In `discoverEligibilityPolicy.js`, when a swipe was rejected due to distance limits, `validateSwipeEligibility` returned an object containing `{ reason: 'distance_exceeded', distance, maxAllowedDistance }`. If logged, the precise floating-point distance would be recorded.

---

## 3. Endpoint-by-Endpoint Privacy Audit

| Endpoint | Method | Location / Distance Data Returned | Privacy Compliant? | Notes |
|---|---|---|---|---|
| `/api/discover/feed` | `GET` | `city`, coarse `distance`/`distanceKm` (multiples of 5), booleans `viewerLocationAvailable`, `distanceFilterActive` | **YES** | Zero coordinates. No raw/precise distances. |
| `/api/discover/ai-matches` | `GET` | `city`, coarse `distance`/`distanceKm` (multiples of 5) | **YES** | Zero coordinates. |
| `/api/discover/feed?surface=near_you` | `GET` | `city`, coarse `distance`/`distanceKm` (multiples of 5) | **YES** | Distance ordering internal to SQL; cursor encrypted AEAD. |
| `/api/profiles/:userId` | `GET` | `city` | **YES** | Coordinates and distance are omitted (`null`). |
| `/api/me/profile` | `GET` | `location` (city), `locationAvailable`, `locationUpdatedAt` | **YES** | User's own coordinates are not echoed back. |
| `/api/me/location` | `GET` | `locationAvailable`, `locationUpdatedAt` | **YES** | Status only. |
| `/api/me/location` | `PUT` | `locationAvailable`, `locationUpdatedAt` | **YES** | Coordinates accepted in body, never returned. |
| `/api/me/location` | `DELETE` | `locationAvailable: false`, `locationUpdatedAt: null` | **YES** | Coordinates cleared. |
| `/api/me/preferences` | `GET` | `preferences`, `locationAvailable`, `locationUpdatedAt` | **YES** | Only distance filter preference (`maxDistanceKm`) returned. |
| `/api/matches` | `GET` | `city` | **YES** | Matches list does not expose coordinates or distance. |
| `/api/matches/:matchId` | `GET` | `city` | **YES** | Match detail does not expose coordinates or distance. |
| `/api/conversations` | `GET` | Participant `city` | **YES** | Zero coordinates. |
| `/api/messages` | `GET` | Participant `city` | **YES** | Zero coordinates. |
| `/api/saved-profiles` | `GET` | `city` | **YES** | Zero coordinates. |
| `/api/blocks` | `GET` | Blocked user `city` | **YES** | Zero coordinates. |
| `/api/onboarding/status` | `GET` | Stripped onboarding profile | **YES** | `matchLatitude` and `matchLongitude` deleted. |

---

## 4. Location and Distance Data-Flow Inventory

```
[Client GPS]
    │  (Consented coordinate submission)
    ▼
PUT /api/me/location { latitude, longitude }
    │
    ▼ (Validation: -90..90, -180..180, no extra fields)
OnboardingProfile.update({ matchLatitude, matchLongitude, locationUpdatedAt })
    │
    ├──► Stored in MySQL `OnboardingProfiles` table (DECIMAL(9,6))
    │
    ├──► Internal Eligibility & Ranking Queries:
    │      ├─ SQL Bounding Box (pre-filter candidates by lat/lon limits)
    │      ├─ SQL Haversine Expression (evaluates distance <= min(viewerMax, candidateMax))
    │      └─ SQL Distance Rank (for Near You surface ordering: ROUND(distanceSql, 6))
    │
    ├──► Keyset Cursor:
    │      └─ Encrypted with AES-256-GCM AEAD (c2.<kid>.<iv>.<ciphertext>.<tag>)
    │
    ├──► Response Serialization:
    │      ├─ OnboardingProfile.prototype.toJSON (strips matchLatitude/matchLongitude)
    │      └─ publicProfileService.serializePublicProfile:
    │           ├─ coarseDistanceKm(distance) -> Math.max(5, Math.ceil(d / 5) * 5)
    │           ├─ coordinates EXCLUDED
    │           └─ raw distance EXCLUDED
    │
    └──► Logger / Diagnostics:
           └─ logger.sanitizeValue (redacts matchLatitude, matchLongitude, latitude, longitude, distanceKmPrecise)
```

---

## 5. Confirmed Vulnerabilities & Severity

| ID | Finding | Severity | Status | Resolution |
|---|---|---|---|---|
| **VULN-P1B-01** | `OnboardingProfile.prototype.toJSON` did not strip `matchLatitude` and `matchLongitude` by default. | **HIGH** | **RESOLVED** | Added model-level `toJSON` override to delete `matchLatitude` and `matchLongitude`. |
| **VULN-P1B-02** | DPDP logger (`logger.js`) did not redact coordinate and precise distance field names. | **MEDIUM** | **RESOLVED** | Added coordinate/distance keys to `SENSITIVE_KEY` regex in `logger.js`. |
| **VULN-P1B-03** | `validateSwipeEligibility` retained precise unrounded distance and max allowed distance in failure return object. | **LOW** | **RESOLVED** | Removed `distance` and `maxAllowedDistance` from the returned rejection object. |

---

## 6. Files Changed and Implementation Details

### 1. `Backend/src/models/OnboardingProfile.js`
Added model-level `toJSON` method to `OnboardingProfile.prototype`:
```javascript
OnboardingProfile.prototype.toJSON = function toJSON() {
  const values = { ...this.get() };
  delete values.matchLatitude;
  delete values.matchLongitude;
  return values;
};
```
*Effect:* Any `profile.toJSON()` or `JSON.stringify(profile)` anywhere in the application automatically excludes GPS coordinates, even if a handler forgets to explicitly delete them.

### 2. `Backend/src/utils/logger.js`
Updated `SENSITIVE_KEY` in `sanitizeValue`:
```javascript
const SENSITIVE_KEY = /(?:password|passphrase|pwd|otp|one.?time|token|authorization|cookie|secret|api.?key|refresh.?token|access.?token|mfa|totp|aadhaar|identity.?document|document.?number|private.?key|client.?secret|matchLatitude|matchLongitude|latitude|longitude|coordinates|exactDistance|distanceKmPrecise|distanceRank)/i;
```
*Effect:* Any log payload containing raw coordinates, precise distance, or distance rank keys replaces the sensitive values with `'[REDACTED_SENSITIVE_FIELD]'`.

### 3. `Backend/src/services/discoverEligibilityPolicy.js`
Updated `validateSwipeEligibility`:
```javascript
if (Number.isFinite(maxAllowedDistance) && distance > maxAllowedDistance) {
  return { eligible: false, code: 'PROFILE_NOT_DISCOVERABLE', stage: 'eligibility', reason: 'distance_exceeded' };
}
```
*Effect:* Replaced `{ reason: 'distance_exceeded', distance, maxAllowedDistance }` with `{ reason: 'distance_exceeded' }`, ensuring precise floating-point distance numbers are not retained in memory or failure diagnostics.

### 4. `Backend/test/location-privacy.test.js`
Created a dedicated test suite with 10 comprehensive tests covering:
- Discover feed response privacy
- AI Matches response privacy
- Near You response privacy
- Public profile response privacy
- Own profile response privacy
- Location management API privacy
- `OnboardingProfile.prototype.toJSON` coordinate stripping
- Logger coordinate/distance automatic redaction
- Swipe eligibility failure object privacy
- Encrypted cursor coordinate protection

---

## 7. Synthetic Before / After API Response Examples

### Example 1: Discover Feed Profile Card
**Before P1-B (Vulnerable to direct Sequelize serialization if uncoarsened):**
```json
{
  "id": "1042",
  "name": "Aarav",
  "city": "Ahmedabad",
  "matchLatitude": 23.022514,
  "matchLongitude": 72.571428,
  "distanceKmPrecise": 3.427189,
  "distance": 3.427189,
  "score": 88
}
```

**After P1-B (Privacy Enforced):**
```json
{
  "id": "1042",
  "name": "Aarav",
  "city": "Ahmedabad",
  "distance": 5,
  "distanceKm": 5,
  "score": 88
}
```
*Note: Distance is coarsened to integer multiples of 5 km ($5, 10, 15, \dots$) with a 5 km minimum floor. Coordinates are completely absent.*

---

### Example 2: Location Update Response (`PUT /api/me/location`)
**Submitted Request Body:**
```json
{
  "latitude": 23.0225,
  "longitude": 72.5714
}
```

**Response (Coordinates Never Echoed Back):**
```json
{
  "success": true,
  "message": "Current location enabled for distance matching.",
  "data": {
    "location": {
      "locationAvailable": true,
      "locationUpdatedAt": "2026-11-02T14:15:00.000Z"
    }
  }
}
```

---

## 8. Test Coverage and Execution Results

### 8.1 Dedicated Location Privacy Test Suite (`location-privacy.test.js`)
```text
✔ 1. Discover feed response contains no exact coordinates or raw distances (522.5396ms)
✔ 2. AI Matches response contains no exact coordinates or raw distances (203.0504ms)
✔ 3. Near You surface response contains no exact coordinates or raw distances (144.7804ms)
✔ 4. Target public profile view contains no coordinates or calculated distance (16.7998ms)
✔ 5. Current user own profile view exposes only city and locationAvailable (7.8691ms)
✔ 6. Location management endpoints (GET, PUT, DELETE) never echo coordinates back (65.0982ms)
✔ 7. OnboardingProfile.prototype.toJSON strips matchLatitude and matchLongitude by default (1.4875ms)
✔ 8. Logger redacts coordinate and precise distance keys automatically (1.0032ms)
✔ 9. validateSwipeEligibility does not retain exact distance in failure object (0.6173ms)
✔ 10. Encrypted recommendation cursors contain zero plaintext coordinates (120.9274ms)
ℹ tests 10 | pass 10 | fail 0 (2083.7282ms)
```

### 8.2 Location & Distance Integration Suite (`location-distance.integration.test.js`)
```text
✔ legacy viewer without coordinates keeps default Discover but Near You requires location
✔ location API enforces authentication, strict coordinates, ownership, and server timestamp
✔ default Discover enforces precise max distance and publishes only rounded distance
✔ one-kilometre boundary is included while a farther candidate is excluded
✔ Near You ranks distance then compatibility then stable user id and city remains independent
✔ Near You cursor preserves distance, compatibility, and id order without duplicates
✔ Near You keyset remains gap-free after page-one action with equal-distance ties
✔ AI Matches shares geographic eligibility and SQL distance agrees with canonical JS
✔ candidate reciprocal age uses inclusive bounds, defaults safely, and never creates preference rows
✔ reciprocal distance uses the same distance for both limits in Discover, Near You, and AI Matches
✔ reciprocal preferences and internal exclusion details never enter public payloads
✔ clearing location does not clear city and restores migration-safe Discover
ℹ tests 12 | pass 12 | fail 0 (5822.6283ms)
```

### 8.3 Recommendation Cursor Suite (`recommendation-cursor.test.js`)
```text
✔ 22 / 22 tests passing (120.4194ms)
```

### 8.4 P0 Safety Remediation Suite (`p0-safety-remediation.integration.test.js`)
```text
✔ 21 / 21 tests passing (5364.4789ms)
```

### 8.5 Discover Eligibility Policy Suite (`discover-eligibility-policy.test.js`)
```text
✔ 11 / 11 tests passing (318.4222ms)
```

### 8.6 Like & Match Persistence Suite (`like-persistence.integration.test.js`)
```text
✔ 6 / 6 tests passing (2381.0367ms)
```

**Grand Total: 82 / 82 tests passing (0 regressions, 0 failures).**

---

## 9. Database and Environment Isolation Confirmation

1. **Zero Production Access:** No connections, deployments, or remote executions were performed on VPS `195.35.23.132` or PM2 process `amora-backend`.
2. **Zero Staging Infrastructure Access:** Staging environments remain untouched.
3. **Local Test Database Isolation:** All tests ran strictly against local MySQL test schema `amora_ai_test` (`127.0.0.1:3306`).
4. **Zero Frontend Modifications:** No Flutter/Dart files were touched.
5. **Zero Secret Leaks:** No credentials, encryption keys, or environment secrets are exposed in code or commits.

---

## 10. Remaining Risks and Limitations

1. **IP-Based Geolocation:** The backend accepts GPS coordinates submitted by the mobile client upon user consent. If the device GPS spoofing occurs client-side, the backend receives the spoofed coordinates.
2. **Trilateration Mitigation:** Coarsening distance to multiples of 5 km with a 5 km floor significantly limits trilateration attacks, but coarse distance together with city labels still narrows a user's presence to a metropolitan area.
3. **Legal Disclaimer:** Technical pass on engineering test suites demonstrates adherence to product and security specifications; it does not constitute a legal certification of full DPDP/GDPR regulatory compliance.

---

## 11. Final Verdict

**`PASS — P1-B COMPLETE`**

Phase 3 P1-B (Location & Distance Privacy Enforcement) is completely implemented and verified across all endpoints, models, serializers, and loggers.

As instructed:
> **"STOP after P1-B. Do not start P1-C (15-minute rewind policy) until I explicitly authorize it."**

We are stopped here awaiting user authorization before commencing **Phase 3 P1-C**.
