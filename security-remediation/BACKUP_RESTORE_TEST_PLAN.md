# Backup and Restore Test Plan

Control: P-05  
Status: **IMPLEMENTED — INFRASTRUCTURE EVIDENCE REQUIRED**. This plan is not completion evidence.

## Prerequisites

- Management-approved RPO and RTO; recovery owner and backup owner assigned.
- Encrypted scheduled backup policy with retention and deletion rules approved by Legal/Privacy.
- Dedicated least-privilege backup identity, separate from the application identity; MFA for human console access.
- Encrypted snapshots and documented key ownership/recovery.
- Isolated, non-production restore network/database with synthetic or approved sanitized data only.

## Drill

1. Record source service/resource IDs, backup policy version, schedule, retention, encryption/key reference and access grants without secrets.
2. Select a dated recovery point and record expected RPO.
3. Restore into the isolated target using the backup identity; never overwrite staging or production.
4. Apply/verify schema and integrity checks; compare approved row/count/checksum fixtures without exposing personal data.
5. Measure backup age, restore start/end, application-readiness time and achieved RPO/RTO.
6. Exercise a safe failure (for example denied grant or invalid target) and verify alert, cleanup and escalation behavior.
7. Remove the recovery target under the approved cleanup policy and retain the sanitized provider job/log reference.

## Pass criteria

Backup schedule and every selected snapshot are encrypted; identity is separate and restricted; retention matches approval; restore succeeds in isolation; integrity checks pass; measured RPO/RTO meet approved targets; failures alert and do not expose or overwrite data; named owners sign the record.

Required evidence: sanitized policy/config export, key reference, grants, backup job ID/time, restore job log, integrity results, measured RPO/RTO, failure/alert result, reviewer/date and cleanup record. A written procedure alone does not close P-05.
