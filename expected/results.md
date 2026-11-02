# Expected verification — PostgreSQL 16

These are expected assertions, **not freshly captured terminal logs for the repository scripts**. Equivalent interactive experiments were run by the author, with 3 + 3 + 5 assertions passing.

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

All three scripts use temporary tables and `ROLLBACK`; `ON_ERROR_STOP` aborts on unexpected failure.
