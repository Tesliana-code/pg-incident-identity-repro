\set ON_ERROR_STOP on
BEGIN;
\echo '=== EXPERIMENT 03: MIGRATION TRAP ==='
CREATE TEMP TABLE migration_incidents (workspace_id text NOT NULL, connector_instance_id text NOT NULL, external_id text NOT NULL, summary text NOT NULL, CONSTRAINT old_unique_external_id UNIQUE (external_id));
INSERT INTO migration_incidents VALUES ('acme','zendesk-eu','1042','Login failure') ON CONFLICT (external_id) DO NOTHING;
INSERT INTO migration_incidents VALUES ('acme','zendesk-us','1042','Payment timeout') ON CONFLICT (external_id) DO NOTHING;
DO $$ BEGIN IF (SELECT count(*) FROM migration_incidents) <> 1 THEN RAISE EXCEPTION 'FAIL A'; END IF; RAISE NOTICE 'PASS A: legacy schema suppressed valid incident'; END $$;
ALTER TABLE migration_incidents ADD CONSTRAINT new_scoped_identity UNIQUE (workspace_id, connector_instance_id, external_id);
ALTER TABLE migration_incidents DROP CONSTRAINT old_unique_external_id;
DO $$ BEGIN IF (SELECT count(*) FROM migration_incidents) <> 1 THEN RAISE EXCEPTION 'FAIL B'; END IF; RAISE NOTICE 'PASS B: migration preserves row count, missing incident remains missing'; END $$;
DO $$ DECLARE rejected boolean := false; BEGIN BEGIN EXECUTE $query$ INSERT INTO migration_incidents VALUES ('acme','zendesk-us','1042','Payment timeout') ON CONFLICT (external_id) DO NOTHING $query$; EXCEPTION WHEN SQLSTATE '42P10' THEN rejected := true; END; IF NOT rejected THEN RAISE EXCEPTION 'FAIL C'; END IF; RAISE NOTICE 'PASS C: old conflict target rejected with 42P10'; END $$;
INSERT INTO migration_incidents VALUES ('acme','zendesk-us','1042','Payment timeout') ON CONFLICT (workspace_id, connector_instance_id, external_id) DO NOTHING;
DO $$ BEGIN IF (SELECT count(*) FROM migration_incidents) <> 2 THEN RAISE EXCEPTION 'FAIL D'; END IF; RAISE NOTICE 'PASS D: missing incident restored by source replay'; END $$;
INSERT INTO migration_incidents VALUES ('acme','zendesk-us','1042','Payment timeout') ON CONFLICT (workspace_id, connector_instance_id, external_id) DO NOTHING RETURNING *;
DO $$ BEGIN IF (SELECT count(*) FROM migration_incidents) <> 2 THEN RAISE EXCEPTION 'FAIL E'; END IF; RAISE NOTICE 'PASS E: subsequent replay creates no duplicate'; END $$;
TABLE migration_incidents;
ROLLBACK;
\echo '=== EXPERIMENT 03 COMPLETE ==='
