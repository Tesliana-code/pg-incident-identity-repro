\set ON_ERROR_STOP on

-- PostgreSQL 16
-- Uniqueness scoped to external_id only

BEGIN;

CREATE TEMP TABLE incoming_incidents (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_system text NOT NULL,
    external_id text NOT NULL,
    summary text NOT NULL,
    CONSTRAINT incoming_external_id_key UNIQUE (external_id)
);

INSERT INTO incoming_incidents
    (source_system, external_id, summary)
VALUES
    ('jira', '1042', 'Authentication outage')
ON CONFLICT (external_id) DO NOTHING;

INSERT INTO incoming_incidents
    (source_system, external_id, summary)
VALUES
    ('zendesk', '1042', 'Payment processing failure')
ON CONFLICT (external_id) DO NOTHING;

-- Retry the Zendesk incident
INSERT INTO incoming_incidents
    (source_system, external_id, summary)
VALUES
    ('zendesk', '1042', 'Payment processing failure')
ON CONFLICT (external_id) DO NOTHING;

SELECT
    source_system,
    external_id,
    summary
FROM incoming_incidents
ORDER BY id;

ROLLBACK;
