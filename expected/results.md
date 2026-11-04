# Expected verification — PostgreSQL 16

All 11 assertions (3 + 3 + 5) passed on PostgreSQL 16.14. Actual execution logs are preserved in `expected/output/`.

| Script | Assertion | Expected evidence |
|---|---|---|
| 01-global-id.sql | A | The second provider's insert reports `INSERT 0 0`; one row retained |
| | B | Two distinct provider rows retained |
| | C | Replay yields zero returned rows and no duplicate |
| 02-connector-collision.sql | A | Provider-level uniqueness retains one of three incident records |
| | B | Workspace/connector-scoped uniqueness retains all three |
| | C | Same-connector replay inserts zero rows |
| 03-migration-trap.sql | A | Legacy key retains one of two |
| | B | New key preserves existing single row, not absent event |
| | C | Old conflict target raises SQLSTATE `42P10` (caught inside DO) |
| | D | Re-delivery inserts missing second row |
| | E | Subsequent replay inserts zero rows |

Experiments 1 and 2 use isolated test databases, removed only after successful execution. Experiment 3 uses a temporary table and `ROLLBACK`. All scripts use `ON_ERROR_STOP`.
