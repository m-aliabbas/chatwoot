#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f .env ]]; then
  echo "Missing .env. Copy .env.example to .env and set the required database values first." >&2
  exit 1
fi

set -a
source .env
set +a

require_var() {
  local variable_name="$1"

  if [[ -z "${!variable_name:-}" ]]; then
    echo "Missing required variable in .env: ${variable_name}" >&2
    exit 1
  fi
}

for variable_name in N8N_DB_PASSWORD VIBE_AI_DB_NAME VIBE_AI_DB_USER VIBE_AI_DB_PASSWORD; do
  require_var "$variable_name"
done

postgres_container="$(docker compose ps -q postgres)"
if [[ -z "${postgres_container}" ]]; then
  echo "PostgreSQL is not running. Start it first with: docker compose up -d postgres" >&2
  exit 1
fi

if [[ "$(docker inspect -f '{{.State.Running}}' "${postgres_container}")" != "true" ]]; then
  echo "PostgreSQL container exists but is not running. Start it first with: docker compose up -d postgres" >&2
  exit 1
fi

psql_exec() {
  local database_name="$1"
  shift

  docker exec -u postgres -i "${postgres_container}" psql -v ON_ERROR_STOP=1 -U postgres -d "${database_name}" "$@"
}

ensure_role() {
  local role_name="$1"
  local role_password="$2"

  psql_exec postgres --set=role_name="$role_name" --set=role_password="$role_password" <<'SQL'
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'role_name') THEN
    EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', :'role_name', :'role_password');
  ELSE
    EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', :'role_name', :'role_password');
  END IF;
END
$$;
SQL
}

ensure_database() {
  local database_name="$1"
  local owner_name="$2"

  psql_exec postgres --set=db_name="$database_name" --set=owner_name="$owner_name" <<'SQL'
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

ensure_role "n8n_user" "${N8N_DB_PASSWORD}"
ensure_database "n8n_vibeexe" "n8n_user"

ensure_role "${VIBE_AI_DB_USER}" "${VIBE_AI_DB_PASSWORD}"
ensure_database "${VIBE_AI_DB_NAME}" "${VIBE_AI_DB_USER}"
enable_vector_extension

printf 'Provisioned %s and %s in PostgreSQL container %s\n' "n8n_vibeexe" "${VIBE_AI_DB_NAME}" "${postgres_container}"