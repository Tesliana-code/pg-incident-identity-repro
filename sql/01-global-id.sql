\set ON_ERROR_STOP on

\echo '=== TEST A: WRONG UNIQUE KEY ==='

CREATE TABLE bad_incidents (
    source_system text NOT NULL,
    external_id text NOT NULL UNIQUE,
    summary text NOT NULL
);

INSERT INTO bad_incidents VALUES
('jira', '1042', 'Authentication outage')
ON CONFLICT (external_id) DO NOTHING;

INSERT INTO bad_incidents VALUES
('zendesk', '1042', 'Payment processing failure')
ON CONFLICT (external_id) DO NOTHING;

SELECT * FROM bad_incidents;

DO $$
BEGIN
  IF (SELECT count(*) FROM bad_incidents) <> 1 THEN
    RAISE EXCEPTION 'FAIL A: expected one row';
  END IF;
  RAISE NOTICE 'PASS A: second incident suppressed';
END $$;

\echo '=== TEST B: CORRECT COMPOSITE KEY ==='

CREATE TABLE good_incidents (
    source_system text NOT NULL,
    external_id text NOT NULL,
    summary text NOT NULL,
    UNIQUE (source_system, external_id)
);

INSERT INTO good_incidents VALUES
('jira', '1042', 'Authentication outage'),
('zendesk', '1042', 'Payment processing failure')
ON CONFLICT (source_system, external_id) DO NOTHING;

SELECT * FROM good_incidents;

DO $$
BEGIN
  IF (SELECT count(*) FROM good_incidents) <> 2 THEN
    RAISE EXCEPTION 'FAIL B: expected two rows';
  END IF;
  RAISE NOTICE 'PASS B: both incidents retained';
END $$;

\echo '=== TEST C: REPLAY ==='

INSERT INTO good_incidents VALUES
('zendesk', '1042', 'Payment processing failure')
ON CONFLICT (source_system, external_id) DO NOTHING
RETURNING *;

DO $$
BEGIN
  IF (SELECT count(*) FROM good_incidents) <> 2 THEN
    RAISE EXCEPTION 'FAIL C: duplicate created';
  END IF;
  RAISE NOTICE 'PASS C: replay did not duplicate incident';
END $$;

\echo '=== ALL ASSERTIONS PASSED ==='
