# Discover frontend audit

## Current route and state

| Area | Source | Current source | Backend requirement |
| --- | --- | --- | --- |
| Discover route | `lib/features/discover/presentation/discover_screen.dart` | Alias to `BrowseGridScreen` | `GET /api/v1/discover/profiles` |
| Discover deck | `lib/features/discover/presentation/browse_grid_screen.dart` | `ImageRepository.profiles` | Paginated discover profile response |
| Deck/action state | `lib/features/discover/presentation/discover_action_controller.dart` | In-memory IDs, local sets, generated mutual likes | Server-authoritative reactions and match response |
| Source profiles | `lib/core/data/image_repository.dart` | 300 generated `DummyProfile` records | Remove from production Discover path; retain only as test/demo fixture |
| Profile detail | `lib/features/profile/presentation/profile_detail_screen.dart` | Receives an entire `DummyProfile` as arguments | Stable profile ID plus a separate detail endpoint |
| Advanced filters | `lib/features/discover/presentation/advanced_filters_screen.dart` | Screen-local state, not returned to Discover | Serializable filter query/state contract |

## Visible Discover card data

| UI data | Current `DummyProfile` field | Current source | Required canonical source |
| --- | --- | --- | --- |
| Stable identity | `id` | Generated string | User/profile primary key |
| Name and age | `name`, `age` | Generated | `Users.name`, server-calculated age from `OnboardingProfile.birthDate` |
| Photos/gallery | `imageUrl`, `gallery` | Bundled assets | Public profile photo records/URLs; current onboarding photo paths are a partial source |
| City and distance | `city`, `distance` | Generated | Onboarding/profile city plus server distance data; distance requires a location product decision |
| Profession/education | `profession`, `education` | Generated | `OnboardingProfile.profession`, `education` |
| Dating intention | `intent` | Generated | `OnboardingProfile.relationshipGoals` |
| Bio/interests | `bio`, `interests` | Generated | `OnboardingProfile.bio`, `interests` |
| Verification/premium badges | `verification`, `premium` | Generated/score-derived | Authoritative verification/subscription tables are absent |
| Online status | `status` | Generated | Presence or last-active system is absent |
| Compatibility | `score`, `compatibility` | Generated | No backend algorithm or product rules exist |
| Lifestyle/prompts | `lifestyle`, `promptAnswers` | Generated | `OnboardingProfile.lifestyle`, `prompts` (partial) |
| Languages/religion/hometown | `languages`, `religion`, `hometown` | Generated | Onboarding lifestyle/hometown fields (partial) |
| Pronouns/sexuality/qualities/love languages | matching fields | Generated | Corresponding `OnboardingProfile` fields |

## Current filters and proposed contract

`AdvancedFiltersScreen` owns local filters. It currently includes age range, distance, city, hometown, relationship intentions, dating types, education, profession, religion/community, languages, minimum height, travel, fitness, coffee, movies, smoking, drinking, weed, qualities, pronouns, sexuality, preferred talking hours, love languages, verified-only, online-only, prompt presence, event interest, and compatibility score.

Across filter categories the UI implies AND semantics; multi-select categories imply OR semantics. The UI does not currently return a filter object to Discover, so connecting filters requires a minimal existing-screen state handoff before backend query integration.

Fields supportable from the current backend schema: age, city, relationship goals, profession, education, hometown, interests, prompts, lifestyle values, pronouns, sexuality, qualities, love languages, preferred talking hours, photos, and verification (`Users.isVerified`).

Fields without a database source or defined semantics: geographic distance, community, dating type, travel, fitness, coffee, movies, online, event interest, premium, and compatibility. These cannot be truthfully implemented without a product/schema decision.

## Current action behavior

| Action | Source | Current behavior | Required backend entity/API |
| --- | --- | --- | --- |
| Like | `BrowseGridScreen._performAction` | Local deck removal and local relationship controller | Reaction table and authenticated reaction endpoint |
| Pass | `BrowseGridScreen._performAction` | Local deck removal only | Persisted pass reaction/exclusion |
| Super Like | `BrowseGridScreen._sendSuperLike` | Local state/animation only | Reaction type plus entitlement policy; no entitlement schema exists |
| Rewind | `DiscoverActionController` | Local history only | Existing product rule not defined |
| Save | Not present in Discover | N/A | Not required by current Discover UI |
| Block | Not reachable from Discover | N/A | Not required by current Discover UI |

## Existing backend/database audit

The existing Node.js/Express/Sequelize MySQL backend currently has only `Users`, `OtpTokens`, `RefreshTokens`, and `OnboardingProfiles`. It has JWT authentication and consistent response envelopes. There are no existing tables/models for public profiles, profile photos, reactions, passes, matches, blocks, saved profiles, subscriptions, verification detail, compatibility, or presence.

`OnboardingProfiles` is the only available profile source. It can support a restricted, truthful Discover response for users who completed onboarding, but it does not supply several fields currently rendered by the generated demo cards.

## Mock data classification

`ImageRepository.profiles` and `DummyProfile` are Discover production-path mock data. They should be removed from the production Discover load path, but retained for tests/demo fixtures until tests are migrated to remote models.

## Required product decisions before a complete production replacement

1. Compatibility algorithm/contract: no server business rules exist; a random or score-derived replacement would be fabricated.
2. Presence contract: no reliable online/last-active source exists.
3. Premium entitlement: no subscription source exists.
4. Distance semantics: city strings are available, but no coordinates or user-distance rule exists.
5. Super Like entitlement and rewind rules: neither is represented in the existing schema.

Without these decisions, a full replacement preserving every existing visual field cannot be completed truthfully. A safe first delivery can expose only the data available from completed onboarding profiles, with server-authoritative like/pass reactions and cursor pagination.
