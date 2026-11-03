# Raw SQL and ORM injection review

Reviewed scope: `Backend/src` Sequelize `query` and `literal` call sites.

## Runtime query classes

- Dashboard, analytics, data-integrity, system-health, event-capacity, and conversation queries use static SQL. Dynamic values are supplied through Sequelize replacements/binds or ORM predicates.
- Discovery SQL fragments use Sequelize identifier quoting for model/table fields and `sequelize.escape` for runtime scalar values. Sort modes and directions are selected from server-owned enumerations.
- Access-control anti-join fragments use model-owned table names, quoted identifiers, and numeric server-authenticated user IDs.
- Administrator verification sorting is allowlisted by the route validator before it reaches the service.

No runtime call site was found that interpolates an unvalidated request string as a SQL value, table name, column name, or order direction.

## Migration queries

Migration raw SQL is repository-static and executes only in the migration runner. It does not accept request data. These statements remain security-sensitive and require code review because they modify schema or retained records.

## Regression expectations

- Dynamic values must use `bind`, `replacements`, ORM predicates, or `sequelize.escape` for scalar values.
- Dynamic identifiers must come from a closed server-side allowlist and be quoted.
- Any future `sequelize.query` or `literal` change must receive security review and an injection-payload regression test.
- Tests must use the isolated test schema only; destructive injection testing against production is prohibited.

Status: repository review completed; runtime database tests were not executed in this remediation environment and remain an evidence gate.

