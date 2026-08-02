#!/usr/bin/env bash
set -euo pipefail

backup_dir="backups"
mkdir -p "${backup_dir}"

postgres_container="$(docker compose ps -q postgres)"
if [[ -z "${postgres_container}" ]]; then
  echo "PostgreSQL is not running. Start it first with: docker compose up -d postgres" >&2
  exit 1
fi

if [[ "$(docker inspect -f '{{.State.Running}}' "${postgres_container}")" != "true" ]]; then
  echo "PostgreSQL container exists but is not running. Start it first with: docker compose up -d postgres" >&2
  exit 1
fi

timestamp="$(date +%F-%H%M%S)"
backup_file="${backup_dir}/postgres-all-${timestamp}.sql"

docker exec -u postgres -i "${postgres_container}" pg_dumpall -U postgres > "${backup_file}"

if [[ ! -s "${backup_file}" ]]; then
  echo "Backup failed: ${backup_file} is empty." >&2
  exit 1
fi

printf '%s\n' "${backup_file}"