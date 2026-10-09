# Environment and Secret Separation

Development, staging and production use distinct databases, JWT families, administrator identities, SMS/email/provider credentials, storage roots, signing keys and monitoring destinations. Development seed credentials are explicit-only and cannot run outside `NODE_ENV=development`. Test databases must contain `test` in their isolated name and never point at production.

Production requires long distinct JWT secrets, an MFA encryption key and HTTPS origins. Real secret values are injected by the deployment platform; `.env`, keys, signing material, service-account files and generated secret output are ignored. Never copy production data into development or tests. Rotation, recovery and access evidence must come from the external secret manager and is not claimed here.
