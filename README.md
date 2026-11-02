# PostgreSQL 16: Incident Identity and `ON CONFLICT`

Three reproducible, synthetic SQL experiments demonstrate how incorrectly scoped uniqueness can make `INSERT ... ON CONFLICT DO NOTHING` suppress legitimate incident records, and why changing a constraint does not reconstruct rows never inserted.

## Requirements

PostgreSQL 16 with `psql`; use a **disposable, nonproduction database** with permission to create temporary tables. No extensions, application data or external dependencies.

## Run

From the repository root, set `TEST_DATABASE_URL` to a disposable PostgreSQL connection string:

```bash
for file in sql/0*.sql; do
  echo "RUNNING $file"
  psql -X -v ON_ERROR_STOP=1 -d "$TEST_DATABASE_URL" -f "$file" || break
done
```

Each script creates only temporary tables inside a transaction and ends with `ROLLBACK`. On an error, `ON_ERROR_STOP` exits `psql` and PostgreSQL rolls back the open transaction when the connection closes.

## Experiments

1. [Global ID collision](sql/01-global-id.sql): `UNIQUE(external_id)` conflates identifiers across two providers; `UNIQUE(source_system, external_id)` preserves both and deduplicates a replay.
2. [Multi-connector collision](sql/02-connector-collision.sql): even a provider-level key can conflate different connector instances and workspaces; a properly scoped composite key preserves all three.
3. [Migration trap](sql/03-migration-trap.sql): replacing the uniqueness constraint does not recover missing incidents; an obsolete `ON CONFLICT` target fails with SQLSTATE `42P10`; re-delivery of retained source records restores the missing example.

See [expected/results.md](expected/results.md). This is an educational reproduction, **not a production migration procedure**.

## Interpretation

The real authority boundary determines the correct unique key. If `connector_instance_id` is already globally unique, including `workspace_id` may be redundant. A row count or `RETURNING` can reveal a skipped insert, but detecting *why* it was skipped requires comparing the source's actual identity. Missing rows can be recovered only when an authoritative source, queue, or log still retains them.

Production changes to constraints need a coordinated application rollout, inspection of existing data, lock/concurrency analysis, and a documented recovery plan.

## PostgreSQL documentation

- [INSERT and ON CONFLICT (v16)](https://www.postgresql.org/docs/16/sql-insert.html)
- [ALTER TABLE (v16)](https://www.postgresql.org/docs/16/sql-altertable.html)

## Attribution

These synthetic example scripts were drafted with AI assistance and exercised by the author against PostgreSQL 16 in earlier equivalent experiments. The expected-results document is **not** a freshly captured test log for these exact repository files. Any use in a publication must follow its editorial policy; disclosure alone does not override authoring restrictions.

## License

MIT — see [LICENSE](LICENSE).
