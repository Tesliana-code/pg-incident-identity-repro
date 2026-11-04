# PostgreSQL 16: Incident Identity and `ON CONFLICT`

Three reproducible, synthetic SQL experiments demonstrate how incorrectly scoped uniqueness can make `INSERT ... ON CONFLICT DO NOTHING` suppress legitimate incident records, and why changing a constraint does not reconstruct rows never inserted.

## Requirements

PostgreSQL 16 with `psql`; use a **disposable, nonproduction database** with permission to create temporary tables. No extensions, application data or external dependencies.

## Test container

Create a disposable PostgreSQL 16 container before running the experiments:

`docker run -d --name pg-incident-article-pg16 --label purpose=pg-incident-article --network none --tmpfs /var/lib/postgresql/data:rw,size=256m --shm-size=64m -e POSTGRES_PASSWORD=article_test_only postgres:16-alpine`

Wait for readiness with `docker exec pg-incident-article-pg16 pg_isready -U postgres -d postgres`.

The container uses temporary in-memory storage and publishes no network ports. If it already exists, inspect it rather than recreating it. Never run these experiments against production data.

## Run

From the repository root, use a dedicated PostgreSQL 16 container labelled `purpose=pg-incident-article`.

Set `CONTAINER` to its name and `PG_USER` to its database user (default: `postgres`).
Example: `export CONTAINER=pg-incident-article-pg16 PG_USER=postgres`.

Run the introductory reproduction with `docker exec -i "$CONTAINER" psql -X -U "$PG_USER" -d postgres -v ON_ERROR_STOP=1 < sql/00-reproduce-failure.sql`.

Run the three experiments with `bash scripts/01-global-id.sh`, `bash scripts/02-connector-collision.sh`, and `bash scripts/03-migration-trap.sh`.

The runners require an existing dedicated test container and do not create one. Never use a production or application container.

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

These synthetic example scripts were drafted with AI assistance and exercised by the author against PostgreSQL 16 in earlier equivalent experiments. Actual PostgreSQL 16.14 execution logs for these repository scripts are preserved in `expected/output/`; all 11 assertions passed. Any use in a publication must follow its editorial policy; disclosure alone does not override authoring restrictions.

## License

MIT — see [LICENSE](LICENSE).
