# n8n VPS Setup

Start from the current repository state and preserve the existing Chatwoot values in `.env`.

```bash
git pull
cp .env.example .env
```

Do not replace an existing production `.env` blindly. Copy the new keys into the file and keep the current Chatwoot settings, especially the existing `SECRET_KEY_BASE`, Redis, mail, and storage values.

Generate secrets as needed:

```bash
openssl rand -hex 32
openssl rand -base64 32
```

Use `openssl rand -hex 32` for `N8N_ENCRYPTION_KEY`, since it produces a 64-character hex string.

Recommended sequence for an existing installation:

```bash
bash scripts/backup-postgres.sh
bash scripts/setup-vibe-databases.sh
docker compose config
docker compose up -d postgres
docker compose up -d n8n
docker compose logs -f n8n
```

Persistence note:

- PostgreSQL data is stored in the named `postgres` volume.
- n8n data and credentials are stored in the named `n8n` volume.
- Do not delete either volume unless you have a verified backup and have confirmed the data was restored successfully.

Validation commands:

```bash
docker compose ps
docker compose exec postgres psql -U postgres -d postgres -c '\l'
docker compose exec postgres psql -U n8n_user -d n8n_vibeexe -c 'SELECT current_database(), current_user;'
docker compose exec postgres psql -U vibe_ai_user -d vibe_ai -c '\dx'
curl -I http://127.0.0.1:5678
```

After you add the Caddy reverse proxy rule, verify the external URL:

```bash
https://n8n.vibeexe.com
```

If the URL does not load, check the n8n container logs and confirm that Caddy is proxying `127.0.0.1:5678`.