# Security drill scenarios

Use these as tabletop inputs; none records a completed exercise.

1. Credential leak: a repository scanner flags a likely production credential. Validate exposure without copying the value, revoke through the owner, inspect use, and preserve evidence.
2. Public media exposure: protected profile or verification media is reachable anonymously. Contain delivery, identify affected objects and access window, validate authorization, and evaluate notices with counsel.
3. Admin compromise: a privileged session performs unexpected destructive actions. Revoke sessions, preserve admin audit trails, scope affected users, and require fresh MFA for recovery.
4. Database exfiltration: unusual egress and queries indicate possible bulk access. Isolate access paths, preserve database/provider logs, scope data categories, and validate clean recovery.
5. OTP abuse: distributed requests target many accounts. Enforce shared throttling, provider controls, enumeration-safe responses, and fraud monitoring.
6. Server compromise: runtime integrity is uncertain. Remove from service, preserve volatile evidence where authorized, rebuild from trusted artifacts, rotate credentials externally, and validate before restoration.
7. Third-party breach: a provider reports possible AMORAA data impact. Invoke the vendor contact path, obtain scope/region/retention evidence, minimize integration access, and track contractual/legal decisions.

