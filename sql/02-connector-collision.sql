\set ON_ERROR_STOP on
BEGIN;
\echo '=== EXPERIMENT 02: CONNECTOR IDENTITY COLLISION ==='
CREATE TEMP TABLE bad_incidents (source_system text NOT NULL, connector_instance_id text NOT NULL, workspace_id text NOT NULL, external_id text NOT NULL, summary text NOT NULL, UNIQUE(source_system, external_id));
INSERT INTO bad_incidents VALUES ('zendesk','zendesk-eu','acme','1042','Login failure'),('zendesk','zendesk-us','acme','1042','Payment timeout'),('zendesk','zendesk-eu','beta','1042','API unavailable') ON CONFLICT (source_system, external_id) DO NOTHING;
DO $$ BEGIN IF (SELECT count(*) FROM bad_incidents) <> 1 THEN RAISE EXCEPTION 'FAIL A'; END IF; RAISE NOTICE 'PASS A: two legitimate incidents suppressed'; END $$;
TABLE bad_incidents;
CREATE TEMP TABLE good_incidents (workspace_id text NOT NULL, connector_instance_id text NOT NULL, external_id text NOT NULL, summary text NOT NULL, UNIQUE (workspace_id, connector_instance_id, external_id));
INSERT INTO good_incidents VALUES ('acme','zendesk-eu','1042','Login failure'),('acme','zendesk-us','1042','Payment timeout'),('beta','zendesk-eu','1042','API unavailable') ON CONFLICT (workspace_id, connector_instance_id, external_id) DO NOTHING;
DO $$ BEGIN IF (SELECT count(*) FROM good_incidents) <> 3 THEN RAISE EXCEPTION 'FAIL B'; END IF; RAISE NOTICE 'PASS B: all three independent incidents retained'; END $$;
TABLE good_incidents;
INSERT INTO good_incidents VALUES ('acme','zendesk-eu','1042','Login failure') ON CONFLICT (workspace_id, connector_instance_id, external_id) DO NOTHING RETURNING *;
DO $$ BEGIN IF (SELECT count(*) FROM good_incidents) <> 3 THEN RAISE EXCEPTION 'FAIL C'; END IF; RAISE NOTICE 'PASS C: repeated delivery created no duplicate'; END $$;
ROLLBACK;
\echo '=== EXPERIMENT 02 COMPLETE ==='
