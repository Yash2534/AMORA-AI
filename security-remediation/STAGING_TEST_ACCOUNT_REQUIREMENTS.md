# Staging Test Account Requirements

Create these identities only in an approved non-production environment. Use unique synthetic addresses/numbers, password-manager-generated credentials, no real PII, and a controlled roster that records creator, expiry and deletion owner.

| Identity | Purpose | Required role | Required state | Required test data | Controls using account |
|---|---|---|---|---|---|
| USER-A | Primary user and ownership boundary actor | Normal user | Active, verified | Synthetic profile, coarse location, media, consent and session | P-11, P-22, P-31, P-36 |
| USER-B | Cross-user denial target/actor | Normal user | Active, verified | Distinct synthetic profile and records owned only by B | P-22, P-31, P-36 |
| UNDERAGE-TEST | Verify server/UI age rejection | No persistent active role unless policy explicitly requires quarantined test state | Synthetic DOB under 18; blocked from onboarding/discovery | No real identity/media | P-25 |
| DEACTIVATED-USER | Visibility/session lifecycle | Normal user | Deactivated, tokens revoked | Synthetic prior profile and session references | P-11, P-31 |
| BLOCKED-PAIR | Two-user block enforcement | Two normal users | Active with directional and reciprocal block cases | Synthetic conversation/discovery state | P-31, P-36 |
| PRIVACY-REQUEST-USER | Access/export/correction/erasure flow | Normal user | Active and identity-verifiable | Synthetic account/profile/consent/request records | P-07, P-22 |
| ADMIN-LOW | RBAC negative tests | Restricted admin | Active, MFA required | Minimum read-only/review permissions | P-37, P-39 |
| ADMIN-FULL | Authorized positive tests | Approved full admin role | Active, MFA required | Only reversible dummy targets | P-37, P-39 |
| MFA-ADMIN | MFA expiry/recovery/step-up | Admin role selected by Security | Active, dedicated test MFA factor | No production permissions; controlled recovery record | P-37 |

Existing local seed tooling is supporting readiness only. It is production-blocked and allowlist-gated, but no account above is considered provisioned until the approved staging roster and validation evidence exist.
