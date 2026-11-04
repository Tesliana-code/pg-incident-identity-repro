\set ON_ERROR_STOP on

\echo '=== TEST A: SOURCE-SCOPED KEY ==='

CREATE TABLE bad_incidents (
    source_system text NOT NULL,
    connector_instance_id text NOT NULL,
    workspace_id text NOT NULL,
    external_id text NOT NULL,
    summary text NOT NULL,
    UNIQUE (source_system, external_id)
);

INSERT INTO bad_incidents VALUES
('zendesk', 'zendesk-eu', 'acme', '1042', 'Login failure'),
('zendesk', 'zendesk-us', 'acme', '1042', 'Payment timeout'),
('zendesk', 'zendesk-eu', 'beta', '1042', 'API unavailable')
ON CONFLICT (source_system, external_id) DO NOTHING;

SELECT workspace_id, connector_instance_id, external_id, summary
FROM bad_incidents;

DO $$
BEGIN
    IF (SELECT count(*) FROM bad_incidents) <> 1 THEN
        RAISE EXCEPTION 'FAIL A: expected 1 retained record';
    END IF;
    RAISE NOTICE 'PASS A: 2 legitimate incidents suppressed';
END $$;

\echo '=== TEST B: WORKSPACE + CONNECTOR INSTANCE KEY ==='

CREATE TABLE good_incidents (
    workspace_id text NOT NULL,
    connector_instance_id text NOT NULL,
    external_id text NOT NULL,
    summary text NOT NULL,
    UNIQUE (workspace_id, connector_instance_id, external_id)
);

INSERT INTO good_incidents VALUES
('acme', 'zendesk-eu', '1042', 'Login failure'),
('acme', 'zendesk-us', '1042', 'Payment timeout'),
('beta', 'zendesk-eu', '1042', 'API unavailable')
ON CONFLICT (workspace_id, connector_instance_id, external_id)
DO NOTHING;

SELECT * FROM good_incidents
ORDER BY workspace_id, connector_instance_id;

DO $$
BEGIN
    IF (SELECT count(*) FROM good_incidents) <> 3 THEN
        RAISE EXCEPTION 'FAIL B: expected 3 independent incidents';
    END IF;
    RAISE NOTICE 'PASS B: all 3 independent incidents retained';
END $$;

\echo '=== TEST C: REPLAY ==='

INSERT INTO good_incidents VALUES
('acme', 'zendesk-eu', '1042', 'Login failure')
ON CONFLICT (workspace_id, connector_instance_id, external_id)
DO NOTHING
RETURNING *;

DO $$
BEGIN
    IF (SELECT count(*) FROM good_incidents) <> 3 THEN
        RAISE EXCEPTION 'FAIL C: replay generated a duplicate';
    END IF;
    RAISE NOTICE 'PASS C: repeated delivery created no duplicate';
END $$;

\echo '=== ALL ASSERTIONS PASSED ==='
