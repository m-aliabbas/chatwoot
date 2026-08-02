#!/usr/bin/env bash
set -euo pipefail

# Docker only runs scripts in docker-entrypoint-initdb.d when the PostgreSQL
# data directory is empty. This script provisions the extra VibeExe databases
# for a fresh installation only.

psql_exec() {
  local database_name="$1"
  shift

  psql --username "${POSTGRES_USER}" --dbname "${database_name}" -v ON_ERROR_STOP=1 "$@"
}

create_role_if_missing() {
  local role_name="$1"
  local role_password="$2"

  psql_exec "${POSTGRES_DB}" --set=role_name="$role_name" --set=role_password="$role_password" <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'role_name') THEN
    EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', :'role_name', :'role_password');
  END IF;
END
$$;
SQL
}

create_database_if_missing() {
  local database_name="$1"
  local owner_name="$2"

  psql_exec "${POSTGRES_DB}" --set=db_name="$database_name" --set=owner_name="$owner_name" <<'SQL'
SELECT format('CREATE DATABASE %I OWNER %I', :'db_name', :'owner_name')
WHERE NOT EXISTS (
  SELECT 1 FROM pg_database WHERE datname = :'db_name'
)
\gexec
SELECT format('ALTER DATABASE %I OWNER TO %I', :'db_name', :'owner_name')
WHERE EXISTS (
  SELECT 1 FROM pg_database WHERE datname = :'db_name'
)
\gexec
SQL
}

enable_vector_extension() {
  psql_exec "${VIBE_AI_DB_NAME}" <<'SQL'
CREATE EXTENSION IF NOT EXISTS vector;
SQL
}

create_role_if_missing "n8n_user" "${N8N_DB_PASSWORD}"
create_database_if_missing "n8n_vibeexe" "n8n_user"

create_role_if_missing "${VIBE_AI_DB_USER}" "${VIBE_AI_DB_PASSWORD}"
create_database_if_missing "${VIBE_AI_DB_NAME}" "${VIBE_AI_DB_USER}"
enable_vector_extension

printf 'Initialized databases: %s, %s\n' "n8n_vibeexe" "${VIBE_AI_DB_NAME}"