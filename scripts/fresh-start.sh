#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

cd "$PROJECT_ROOT"

echo
echo "WARNING: This deletes all Docker Compose volumes for this project."
echo "This includes Chatwoot, PostgreSQL, Redis, and n8n data."
echo

if [[ "${1:-}" != "--yes" ]]; then
  read -r -p "Type RESET to continue: " confirmation

  if [[ "$confirmation" != "RESET" ]]; then
    echo "Cancelled."
    exit 1
  fi
fi

required_variables=(
  POSTGRES_PASSWORD
  N8N_DB_PASSWORD
  N8N_ENCRYPTION_KEY
  VIBE_AI_DB_PASSWORD
)

if [[ ! -f .env ]]; then
  echo "Missing .env file." >&2
  exit 1
fi

echo "Validating Docker Compose..."
docker compose config --quiet

echo "Validating initialization script..."
bash -n docker/postgres/initdb/01-create-vibe-databases.sh

echo "Checking required container variables..."

docker compose run --rm --no-deps \
  --entrypoint sh postgres -c '
    missing=0

    for variable in \
      POSTGRES_PASSWORD \
      N8N_DB_PASSWORD \
      VIBE_AI_DB_PASSWORD
    do
      if [ -n "$(printenv "$variable" || true)" ]; then
        echo "$variable=present"
      else
        echo "$variable=MISSING"
        missing=1
      fi
    done

    exit "$missing"
  '

echo "Removing old containers and volumes..."
docker compose down -v --remove-orphans

echo "Starting PostgreSQL..."
docker compose up -d postgres

postgres_container="$(docker compose ps -q postgres)"

if [[ -z "$postgres_container" ]]; then
  echo "PostgreSQL container was not created." >&2
  exit 1
fi

echo "Waiting for PostgreSQL..."

for attempt in $(seq 1 60); do
  status="$(
    docker inspect \
      --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
      "$postgres_container"
  )"

  if [[ "$status" == "healthy" ]]; then
    echo "PostgreSQL is healthy."
    break
  fi

  if [[ "$status" == "unhealthy" ]]; then
    echo "PostgreSQL is unhealthy." >&2
    docker compose logs --tail=200 postgres
    exit 1
  fi

  if [[ "$attempt" -eq 60 ]]; then
    echo "Timed out waiting for PostgreSQL." >&2
    docker compose logs --tail=200 postgres
    exit 1
  fi

  sleep 2
done

echo "Verifying databases..."
docker compose exec -T postgres \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c '\l'

echo "Verifying database roles..."
docker compose exec -T postgres \
  psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c '\du'

echo "Verifying pgvector..."
docker compose exec -T postgres \
  psql -U postgres -d vibe_ai -v ON_ERROR_STOP=1 \
  -c "SELECT extname FROM pg_extension WHERE extname = 'vector';"

echo "Starting Redis..."
docker compose up -d redis

echo "Preparing Chatwoot database..."
docker compose run --rm rails \
  bundle exec rails db:chatwoot_prepare

echo "Starting all services..."
docker compose up -d

echo
docker compose ps
echo
echo "Fresh stack initialization completed successfully."
