#!/usr/bin/env bash
set -e

CONTAINER="${CONTAINER:-}"
PG_USER="${PG_USER:-postgres}"

if [ -z "$CONTAINER" ]; then
  echo "ERROR: Dedicated test container is required."
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

echo "=== RUN EXPERIMENT 3 ==="

docker exec -i "$CONTAINER" \
  psql -X -U "$PG_USER" -d postgres \
  -v ON_ERROR_STOP=1 \
  < sql/03-migration-trap.sql

echo "=== EXPERIMENT 3 COMPLETE ==="
echo "Temporary tables and transaction rolled back."
