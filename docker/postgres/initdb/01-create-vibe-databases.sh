#!/usr/bin/env bash
set -Eeuo pipefail

# This script is mounted relative to docker-compose.yaml:
# ./docker/postgres/initdb:/docker-entrypoint-initdb.d:ro
#
# PostgreSQL executes it automatically only when its data directory is empty.

: "${POSTGRES_USER:=postgres}"
: "${N8N_DB_PASSWORD:?N8N_DB_PASSWORD is required}"
: "${VIBE_AI_DB_PASSWORD:?VIBE_AI_DB_PASSWORD is required}"

N8N_DB_NAME="${N8N_DB_NAME:-n8n_vibeexe}"
N8N_DB_USER="${N8N_DB_USER:-n8n_user}"

VIBE_AI_DB_NAME="${VIBE_AI_DB_NAME:-vibe_ai}"
VIBE_AI_DB_USER="${VIBE_AI_DB_USER:-vibe_ai_user}"

create_role_and_database() {
  local role_name="$1"
  local role_password="$2"
  local database_name="$3"

  psql \
    --username "$POSTGRES_USER" \
    --dbname postgres \
    --set=ON_ERROR_STOP=1 \
    --set=role_name="$role_name" \
    --set=role_password="$role_password" \
    --set=database_name="$database_name" <<'SQL'
SELECT format(
  'CREATE ROLE %I WITH LOGIN PASSWORD %L',
  :'role_name',
  :'role_password'
)
WHERE NOT EXISTS (
  SELECT 1
  FROM pg_roles
  WHERE rolname = :'role_name'
)
\gexec

SELECT format(
  'ALTER ROLE %I WITH LOGIN PASSWORD %L',
  :'role_name',
  :'role_password'
)
\gexec

SELECT format(
  'CREATE DATABASE %I OWNER %I',
  :'database_name',
  :'role_name'
)
WHERE NOT EXISTS (
  SELECT 1
  FROM pg_database
  WHERE datname = :'database_name'
)
\gexec

SELECT format(
  'ALTER DATABASE %I OWNER TO %I',
  :'database_name',
  :'role_name'
)
\gexec
SQL
}

echo "Creating n8n role and database..."
create_role_and_database \
  "$N8N_DB_USER" \
  "$N8N_DB_PASSWORD" \
  "$N8N_DB_NAME"

echo "Creating Vibe AI role and database..."
create_role_and_database \
  "$VIBE_AI_DB_USER" \
  "$VIBE_AI_DB_PASSWORD" \
  "$VIBE_AI_DB_NAME"

echo "Enabling pgvector in ${VIBE_AI_DB_NAME}..."
psql \
  --username "$POSTGRES_USER" \
  --dbname "$VIBE_AI_DB_NAME" \
  --set=ON_ERROR_STOP=1 \
  --command='CREATE EXTENSION IF NOT EXISTS vector;'

echo "Vibe databases initialized successfully."