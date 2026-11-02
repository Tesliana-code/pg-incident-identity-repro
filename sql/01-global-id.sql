\set ON_ERROR_STOP on
BEGIN;
\echo '=== EXPERIMENT 01: GLOBAL ID COLLISION ==='
CREATE TEMP TABLE bad_incidents (source_system text NOT NULL, external_id text NOT NULL UNIQUE, summary text NOT NULL);
INSERT INTO bad_incidents VALUES ('jira','1042','Authentication outage') ON CONFLICT (external_id) DO NOTHING;
INSERT INTO bad_incidents VALUES ('zendesk','1042','Payment processing failure') ON CONFLICT (external_id) DO NOTHING;
DO $$ BEGIN IF (SELECT count(*) FROM bad_incidents) <> 1 THEN RAISE EXCEPTION 'FAIL A'; END IF; RAISE NOTICE 'PASS A: second source incident suppressed'; END $$;
TABLE bad_incidents;
CREATE TEMP TABLE good_incidents (source_system text NOT NULL, external_id text NOT NULL, summary text NOT NULL, UNIQUE(source_system,external_id));
INSERT INTO good_incidents VALUES ('jira','1042','Authentication outage'),('zendesk','1042','Payment processing failure') ON CONFLICT (source_system,external_id) DO NOTHING;
DO $$ BEGIN IF (SELECT count(*) FROM good_incidents) <> 2 THEN RAISE EXCEPTION 'FAIL B'; END IF; RAISE NOTICE 'PASS B: both distinct incidents retained'; END $$;
TABLE good_incidents;
INSERT INTO good_incidents VALUES ('zendesk','1042','Payment processing failure') ON CONFLICT (source_system,external_id) DO NOTHING RETURNING *;
DO $$ BEGIN IF (SELECT count(*) FROM good_incidents) <> 2 THEN RAISE EXCEPTION 'FAIL C'; END IF; RAISE NOTICE 'PASS C: replay did not create duplicate'; END $$;
ROLLBACK;
\echo '=== EXPERIMENT 01 COMPLETE ==='
