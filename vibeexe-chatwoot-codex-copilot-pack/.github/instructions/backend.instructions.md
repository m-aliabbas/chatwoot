---
applyTo: "app/**/*.rb,lib/**/*.rb,spec/**/*.rb,db/**/*.rb,config/routes.rb"
---

# Backend Instructions

- Follow existing Rails and Chatwoot conventions in adjacent code.
- Scope tenant-owned records through the authenticated/current account.
- Re-authorize client-supplied IDs through the tenant boundary.
- Keep controllers thin; prefer services for orchestration.
- Use transactions for atomic multi-record operations.
- Use idempotent jobs for external, slow, or retryable work.
- Prefer additive, reversible, production-safe migrations.
- Add indexes for new foreign keys and common filters.
- Add RSpec coverage for behavior, authorization, failure paths, and tenant isolation.
- Never commit or log credentials, provider tokens, webhook secrets, or sensitive payloads.
