# Database Infrastructure Evidence

- Acceptable: provider encryption/key and snapshot exports, private endpoint/firewall topology, TLS-required positive and plaintext-negative result, least-privilege app/backup grants and dated access review.
- Unacceptable: Sequelize config alone, passwords/connection strings, an unrestricted connectivity screenshot or undocumented console claims.
- Redact: passwords, tokens, full account numbers, unrelated resources and sensitive IPs; preserve resource class, encryption state, rule intent and grantee permissions.
- Provider: Database and Infrastructure owners; reviewed by Security.
- Pass: encrypted service/snapshots, verified TLS, no public exposure, least-privilege separate identities and approved access review.
