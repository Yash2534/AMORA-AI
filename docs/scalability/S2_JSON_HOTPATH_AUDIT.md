# AMORAA S2 JSON hot-path audit

| Field | Table | Hot use | Expression | Indexability | Candidate direction | Decision |
|---|---|---|---|---|---|---|
| interestedIn | OnboardingProfiles | reciprocal discovery eligibility | `JSON_CONTAINS`, `JSON_LENGTH`, lower/canonical variants | Not normally B-tree indexable | normalized preference relation or controlled generated flags | DEFER; semantics are multi-value and safety-sensitive. |
| relationshipGoals | OnboardingProfiles | compatibility/filtering | JSON extraction/table/search | Not directly | normalized taxonomy join or precomputed feature | DEFER; retain exact scoring semantics. |
| interests | OnboardingProfiles | compatibility score | bounded JSON item extraction | Not directly | feature/snapshot table | DEFER to recommendation serving design. |
| languages | OnboardingProfiles | filter and compatibility | `JSON_CONTAINS` / bounded extraction | Not directly | user-language relation | Candidate only if staging proves hot. |
| lifestyle | OnboardingProfiles | lifestyle tags | `JSON_SEARCH(LOWER(...))` | Not directly | normalized approved tags | P1 candidate; leading hot JSON scan today. |
| prompts | OnboardingProfiles | `hasPrompts` | `JSON_LENGTH` | Function prevents ordinary index use | generated boolean `hasPrompts` | Best small generated-column candidate, but defer until query frequency evidence. |
| pronouns | OnboardingProfiles | optional discovery filter | JSON contains | Not directly | normalized relation | P2. |
| valuedQualities | OnboardingProfiles | optional filter/score | JSON extraction | Not directly | feature table | P2. |
| loveLanguages | OnboardingProfiles | optional filter | JSON contains | Not directly | normalized relation | P2. |
| preferredTalkingHours | OnboardingProfiles | optional filter | JSON contains | Not directly | normalized relation | P2. |
| metadata/context/data | Payments, Messages, Notifications, audit/privacy tables | payload storage | not used for core hot ordering | N/A | keep document-style | Do not index speculatively. |

S2 intentionally does not normalize all JSON fields. The hot query remains bounded and gains an indexable location prefilter, while JSON normalization requires product-controlled taxonomy and backfill decisions. Authentication, authorization, block state, privacy isolation, and account state are never cached or denormalized away.
