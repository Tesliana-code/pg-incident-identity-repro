#!/usr/bin/env bash
set -e

DB="article_dedup_test"
CONTAINER="${CONTAINER:-}"
PG_USER="${PG_USER:-postgres}"

if [ -z "$CONTAINER" ]; then
  echo "ERROR: Set CONTAINER to the dedicated article test container."
  exit 1
fi

if [ "$CONTAINER" != "pg-incident-article-pg16" ]; then
  echo "ERROR: Unexpected test container."
  exit 1
fi

cd "$(dirname "$0")/.."

echo "=== VERIFY TEST CONTAINER ==="
LABEL=$(docker inspect "$CONTAINER" \
  --format '{{index .Config.Labels "purpose"}}')

if [ "$LABEL" != "pg-incident-article" ]; then
  echo "ERROR: Not the dedicated article test container."
  exit 1
fi

VERSION=$(docker exec "$CONTAINER" \
  psql -X -U "$PG_USER" -d postgres -Atc \
  'SHOW server_version_num')

if [ "${VERSION:0:2}" != "16" ]; then
  echo "ERROR: PostgreSQL 16 required. Got $VERSION."
  exit 1
fi

echo "=== POSTGRES READINESS ==="
docker exec "$CONTAINER" \
  pg_isready -U "$PG_USER" -d postgres

echo "=== CREATE ISOLATED TEST DATABASE ==="
EXISTS=$(docker exec "$CONTAINER" \
  psql -X -U "$PG_USER" -d postgres -Atc \
  "SELECT 1 FROM pg_database WHERE datname = '$DB'")

if [ "$EXISTS" = "1" ]; then
  echo "ERROR: Database $DB already exists. Refusing to overwrite."
  exit 1
fi

docker exec "$CONTAINER" createdb -U "$PG_USER" "$DB"

echo "=== RUN EXPERIMENT 1 ==="
docker exec -i "$CONTAINER" \
  psql -X -U "$PG_USER" -d "$DB" \
  -v ON_ERROR_STOP=1 \
  < sql/01-global-id.sql

echo "=== CLEANUP AFTER SUCCESS ==="
docker exec "$CONTAINER" dropdb -U "$PG_USER" "$DB"

echo "=== EXPERIMENT 1 COMPLETE ==="
