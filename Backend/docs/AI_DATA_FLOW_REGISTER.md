# AI and Automated Matching Data-Flow Register

Source inspection shows no executable external AI provider. `aiMatchProvider.js` pins `PROVIDER = 'LOCAL'`; environment/client flags cannot enable a remote provider. The service consumes only deterministic compatibility factors and does not send a network payload.

| Path | Source fields | Outbound fields | Identifier | Provider/region | Retention/training | Purpose/minimization |
|---|---|---|---|---|---|---|
| Compatibility scoring | relationship goals, communication style, interests, languages, city, smoking/drinking/weed | None outside process | Candidate/user IDs used only by calling ranking flow | `LOCAL`; no region claim | No provider retention/training exists | Scores compatibility; free-text bio, email, phone and exact coordinates are excluded |
| Recommendation ranking | compatibility score/factors and internal candidate ID | None outside process | Internal ID for stable ordering | `LOCAL` | Database telemetry is governed separately | Rank eligible candidates after access/visibility filters |
| User-facing reasons | bounded shared factor values | API reason labels/text | No email/phone/token | `LOCAL` | Normal API/log policy | At most three sanitized highlights; control characters, angle brackets and `@` values rejected |

Unknown vendor facts must not be added. If a future external provider is introduced, release is blocked until its endpoint, legal entity, region, payload fields, identifiers, logging, retention, training use, DPA, deletion behavior and failure fallback are recorded and approved. A deterministic authorization/minimization test must prove private preferences, bio, contact data, credentials, identity documents and exact coordinates are absent.
