# Variables
APP_NAME := chatwoot
RAILS_ENV ?= development
DOCKER_COMPOSE := docker compose

# Local development setup
setup:
	gem install bundler
	bundle install
	pnpm install

db_create:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:create

db_migrate:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:migrate

db_seed:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:seed

db_reset:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:reset

db:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:chatwoot_prepare

console:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails console

server:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails server -b 0.0.0.0 -p 3000

burn:
	bundle && pnpm install

run:
	@if [ -f ./.overmind.sock ]; then \
		echo "Overmind is already running. Use 'make force_run' to start a new instance."; \
	else \
		overmind start -f Procfile.dev; \
	fi

force_run:
	@echo "Cleaning up Overmind processes..."
	@lsof -ti:3036 2>/dev/null | xargs kill -9 2>/dev/null || true
	@lsof -ti:3000 2>/dev/null | xargs kill -9 2>/dev/null || true
	@rm -f ./.overmind.sock
	@rm -f tmp/pids/*.pid
	@echo "Cleanup complete"
	overmind start -f Procfile.dev

force_run_tunnel:
	lsof -ti:3000 | xargs kill -9 2>/dev/null || true
	rm -f ./.overmind.sock
	rm -f tmp/pids/*.pid
	overmind start -f Procfile.tunnel

debug:
	overmind connect backend

debug_worker:
	overmind connect worker

docker:
	docker build -t $(APP_NAME) -f ./docker/Dockerfile .

# Docker Compose commands

compose-validate:
	@$(DOCKER_COMPOSE) config --quiet
	@echo "Docker Compose configuration is valid."

compose-up:
	@$(DOCKER_COMPOSE) up -d

compose-down:
	@$(DOCKER_COMPOSE) down

compose-restart:
	@$(DOCKER_COMPOSE) down
	@$(DOCKER_COMPOSE) up -d

compose-status:
	@$(DOCKER_COMPOSE) ps

compose-logs:
	@$(DOCKER_COMPOSE) logs -f --tail=150

postgres-logs:
	@$(DOCKER_COMPOSE) logs -f --tail=150 postgres

n8n-logs:
	@$(DOCKER_COMPOSE) logs -f --tail=150 n8n

chatwoot-logs:
	@$(DOCKER_COMPOSE) logs -f --tail=150 rails sidekiq

# Deletes all Compose volumes and creates a fresh stack.
fresh-start:
	@bash scripts/fresh-start.sh

# Same as fresh-start, but skips confirmation.
fresh-start-force:
	@bash scripts/fresh-start.sh --yes

docker-db-prepare:
	@$(DOCKER_COMPOSE) run --rm rails \
		bundle exec rails db:chatwoot_prepare

verify-databases:
	@echo "Databases:"
	@$(DOCKER_COMPOSE) exec -T postgres \
		psql -U postgres -d postgres -c '\l'
	@echo
	@echo "Roles:"
	@$(DOCKER_COMPOSE) exec -T postgres \
		psql -U postgres -d postgres -c '\du'
	@echo
	@echo "Vibe AI extensions:"
	@$(DOCKER_COMPOSE) exec -T postgres \
		psql -U postgres -d vibe_ai -c '\dx'

.PHONY: \
	setup \
	db_create \
	db_migrate \
	db_seed \
	db_reset \
	db \
	console \
	server \
	burn \
	run \
	force_run \
	force_run_tunnel \
	debug \
	debug_worker \
	docker \
	compose-validate \
	compose-up \
	compose-down \
	compose-restart \
	compose-status \
	compose-logs \
	postgres-logs \
	n8n-logs \
	chatwoot-logs \
	fresh-start \
	fresh-start-force \
	docker-db-prepare \
	verify-databases