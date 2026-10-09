# Exact Remediation File Inventory

- Source baseline: `eeeee8165714976a4cdad7d5a1dd460907c9bbf9` on `main`.
- Working branch: `security/amoraa-pending-remediation`.

Inventory method: `git status --porcelain=v1 -uall`, reconciled with the evidence files created by this verification task.

The pre-existing user-owned file `android/build/reports/problems/problems-report.html` is intentionally excluded. It was modified before remediation and was not edited for security remediation.

Document subtypes: A = final technical document; B = draft requiring manual approval; C = template only; D = external evidence placeholder; E = legal review required; F = management signoff required; G = security-operations approval required.

| Exact path | Classification |
|---|---|
| `.gitignore` | SECURITY CONFIG |
| `Backend/.env.example` | BACKEND CONFIG |
| `Backend/scripts/financial-e2e-fixture.js` | CODE |
| `Backend/scripts/kyc-e2e-fixture.js` | CODE |
| `Backend/scripts/test-db-connect.js` | CODE — deleted obsolete credential-probing path |
| `Backend/scripts/verify-full-application-flow.js` | CODE |
| `Backend/scripts/verify-membership-plans-flow.js` | CODE |
| `Backend/src/admin/permissions.js` | CODE |
| `Backend/src/config/bootstrapEnv.js` | BACKEND CONFIG |
| `Backend/src/config/db.js` | BACKEND CONFIG |
| `Backend/src/config/env.js` | BACKEND CONFIG |
| `Backend/src/config/originPolicy.js` | BACKEND CONFIG |
| `Backend/src/config/seedDefaultAdmin.js` | BACKEND CONFIG |
| `Backend/src/config/trustProxy.js` | BACKEND CONFIG |
| `Backend/src/controllers/accountController.js` | CODE |
| `Backend/src/controllers/authController.js` | CODE |
| `Backend/src/controllers/mediaController.js` | CODE |
| `Backend/src/controllers/onboardingController.js` | CODE |
| `Backend/src/controllers/privacyController.js` | CODE |
| `Backend/src/controllers/privacyRequestController.js` | CODE |
| `Backend/src/controllers/profileController.js` | CODE |
| `Backend/src/middleware/errorHandler.js` | CODE |
| `Backend/src/middleware/profileValidation.js` | CODE |
| `Backend/src/middleware/rateLimiter.js` | CODE |
| `Backend/src/migrations/202610090001-harden-privacy-export-lifecycle.js` | CODE |
| `Backend/src/migrations/202610090002-add-privacy-grievance-admin-permissions.js` | CODE |
| `Backend/src/models/PrivacyExportArtifact.js` | CODE |
| `Backend/src/policies/agePolicy.js` | CODE |
| `Backend/src/routes/adminAuthRoutes.js` | CODE |
| `Backend/src/routes/adminManagementRoutes.js` | CODE |
| `Backend/src/routes/adminRoutes.js` | CODE |
| `Backend/src/routes/adminSafetyRoutes.js` | CODE |
| `Backend/src/routes/adminSystemRoutes.js` | CODE |
| `Backend/src/routes/authRoutes.js` | CODE |
| `Backend/src/routes/mediaRoutes.js` | CODE |
| `Backend/src/routes/onboardingRoutes.js` | CODE |
| `Backend/src/routes/privacyRequestRoutes.js` | CODE |
| `Backend/src/routes/privacyRoutes.js` | CODE |
| `Backend/src/server.js` | CODE |
| `Backend/src/services/adminAuditService.js` | CODE |
| `Backend/src/services/adminFinancialService.js` | CODE |
| `Backend/src/services/adminPasswordMailer.js` | CODE |
| `Backend/src/services/notificationService.js` | CODE |
| `Backend/src/services/privacyExportArtifactService.js` | CODE |
| `Backend/src/services/publicProfileService.js` | CODE |
| `Backend/src/utils/identityVerificationStorage.js` | CODE |
| `Backend/src/utils/logger.js` | CODE |
| `Backend/src/utils/photoStorage.js` | CODE |
| `Backend/src/utils/sendEmail.js` | CODE |
| `Backend/src/utils/sendSms.js` | CODE |
| `Backend/test/auth-onboarding.integration.test.js` | TEST |
| `Backend/test/change-password.integration.test.js` | TEST |
| `Backend/test/privacy-requests.integration.test.js` | TEST |
| `Backend/test/production-hardening.test.js` | TEST |
| `Backend/test/security-remediation.unit.test.js` | TEST |
| `android/app/build.gradle.kts` | MOBILE CONFIG |
| `android/app/src/main/AndroidManifest.xml` | MOBILE CONFIG |
| `lib/core/auth/auth_service.dart` | CODE |
| `lib/core/config/amora_api_config.dart` | MOBILE CONFIG |
| `lib/core/widgets/amoraa_adaptive_image.dart` | CODE |
| `.github/workflows/security.yml` | CI/CD CONFIG |
| `.gitleaks.toml` | SECURITY CONFIG |
| `SECURITY.md` | DOCUMENT — B/G |
| `Backend/docs/ACCOUNT_DELETION_DATA_MAP.md` | DOCUMENT — B/E |
| `Backend/docs/ADMIN_ROUTE_SECURITY_MATRIX.md` | DOCUMENT — A |
| `Backend/docs/AI_DATA_FLOW_REGISTER.md` | DOCUMENT — B |
| `Backend/docs/API_ROUTE_SECURITY_MATRIX.md` | DOCUMENT — A |
| `Backend/docs/CONSENT_PURPOSE_REVIEW_REQUIRED.md` | DOCUMENT — E |
| `Backend/docs/RAW_SQL_INJECTION_REVIEW.md` | DOCUMENT — A |
| `docs/release/RELEASE_SECURITY_CHECKLIST.md` | CHECKLIST — B/F |
| `docs/security/ENVIRONMENT_SEPARATION.md` | DOCUMENT — A |
| `docs/security/INCIDENT_CONTACT_ROLES_TEMPLATE.md` | EVIDENCE TEMPLATE — C/F |
| `docs/security/INCIDENT_EVIDENCE_CHECKLIST.md` | CHECKLIST — C/G |
| `docs/security/INCIDENT_RESPONSE_PLAN.md` | RUNBOOK — B/G |
| `docs/security/INCIDENT_SEVERITY_MATRIX.md` | DOCUMENT — B/G |
| `docs/security/PATCH_SLA.md` | POLICY TEMPLATE — B/F |
| `docs/security/SECURE_RELEASE_PROCESS.md` | RUNBOOK — B/F |
| `docs/security/SECURITY_DRILL_SCENARIOS.md` | EVIDENCE TEMPLATE — C |
| `docs/security/TABLETOP_EXERCISE_TEMPLATE.md` | EVIDENCE TEMPLATE — C |
| `docs/security/VULNERABILITY_MANAGEMENT.md` | POLICY TEMPLATE — B/G |
| `security-remediation/AMORAA_SECURITY_COMPLIANCE_FINAL_REPORT.md` | DOCUMENT — A |
| `security-remediation/BLOCKED_EXTERNAL_ITEMS.md` | DOCUMENT — D |
| `security-remediation/SECURITY_EVIDENCE_INDEX.md` | DOCUMENT — A |
| `security-remediation/SECURITY_REMEDIATION_MATRIX.md` | DOCUMENT — A |
| `security-remediation/REMEDIATION_FILE_INVENTORY.md` | DOCUMENT — A |
| `security-remediation/DOCUMENT_EVIDENCE_REGISTER.md` | DOCUMENT — A |
| `security-remediation/MANUAL_VERIFICATION_REGISTER.md` | DOCUMENT — D |
| `security-remediation/REAL_WORLD_VERIFICATION_REGISTER.md` | DOCUMENT — D |
| `security-remediation/LEGAL_VERIFICATION_REGISTER.md` | DOCUMENT — E |
| `security-remediation/MANAGEMENT_OPERATIONS_SIGNOFF.md` | DOCUMENT — F |
| `security-remediation/RUNTIME_VALIDATION_PLAN.md` | DOCUMENT — A |
| `security-remediation/AMORAA_ACTUAL_VERIFICATION_STATUS.md` | DOCUMENT — A |
| `security-remediation/AMORAA_MANUAL_ACTION_CHECKLIST.md` | CHECKLIST — D/F |
| `security-remediation/PRODUCTION_SECURITY_RELEASE_GATE.md` | CHECKLIST — F/G |
| `security-remediation/AMORAA_SECURITY_REAL_VERIFICATION_REPORT.md` | DOCUMENT — A |
| `security-remediation/AMORAA_LOCAL_RUNTIME_VALIDATION_REPORT.md` | DOCUMENT — A |
| `security-remediation/LOCAL_TEST_ENVIRONMENT_DISCOVERY.md` | DOCUMENT — A |
| `security-remediation/evidence/README.md` | EVIDENCE TEMPLATE — C |
| `security-remediation/evidence/code/README.md` | EVIDENCE TEMPLATE — C |
| `security-remediation/evidence/tests/README.md` | EVIDENCE TEMPLATE — C |
| `security-remediation/evidence/manual/README.md` | EVIDENCE TEMPLATE — C |
| `security-remediation/evidence/infrastructure/README.md` | EVIDENCE TEMPLATE — C |
| `security-remediation/evidence/legal/README.md` | EVIDENCE TEMPLATE — C |
| `security-remediation/evidence/management/README.md` | EVIDENCE TEMPLATE — C |
| `security-remediation/evidence/store/README.md` | EVIDENCE TEMPLATE — C |
| `security-remediation/evidence/vapt/README.md` | EVIDENCE TEMPLATE — C |
| `security-remediation/evidence/drills/README.md` | EVIDENCE TEMPLATE — C |
| `security-remediation/evidence/tests/backend/security-unit-and-hardening.md` | DOCUMENT — A (runtime evidence) |
| `security-remediation/evidence/tests/backend/full-baseline.md` | DOCUMENT — A (runtime evidence) |
| `security-remediation/evidence/tests/flutter/baseline.md` | DOCUMENT — A (runtime evidence) |
| `security-remediation/evidence/tests/secrets/local-secret-scan.md` | DOCUMENT — A (scan evidence) |
| `security-remediation/evidence/tests/dependencies/offline-audit.md` | DOCUMENT — A (audit evidence) |
| `security-remediation/evidence/tests/static/source-checks.md` | DOCUMENT — A (static evidence) |

Total remediation paths in this reconciled inventory: **113**. Git status remains the live authority if later edits add or remove paths.

