# PostgreSQL Volume Migration

The existing Compose file previously mounted the PostgreSQL named volume at `/data/postgres`, but the PostgreSQL image actually stores database files in `/var/lib/postgresql/data`. That mismatch can leave the real data in an anonymous volume while the named `postgres` volume stays empty.

Before changing anything else, inspect the current mounts:

```bash
docker inspect "$(docker compose ps -q postgres)" --format '{{json .Mounts}}'
```

If you see an anonymous volume mounted at `/var/lib/postgresql/data`, that is where the current Chatwoot data likely lives. Do not remove it until you have confirmed the databases are present elsewhere and the backup is valid.

Create a backup first:

```bash
bash scripts/backup-postgres.sh
```

To stop the stack without deleting any volumes:

```bash
docker compose down
```

Do not use `docker compose down -v`. That would delete volumes and can permanently remove the current Chatwoot data.

After correcting the mount path in Compose, bring PostgreSQL back up and then start the dependent services:

```bash
docker compose up -d postgres
docker compose up -d n8n
```

If the expected databases are missing after startup, restore the backup into PostgreSQL:

```bash
docker compose exec -T postgres psql -U postgres -d postgres < backups/postgres-all-YYYY-MM-DD-HHMMSS.sql
```

Only consider removing the old anonymous volume after you have verified Chatwoot can read the existing database data and the backup restores cleanly.