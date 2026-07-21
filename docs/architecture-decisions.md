# Architecture Decision Log

Use short entries for decisions that affect future implementation.

## ADR template

### ADR-000: Title

- **Date:** YYYY-MM-DD
- **Status:** Proposed / Accepted / Superseded
- **Context:** Why a decision is needed.
- **Decision:** What was chosen.
- **Consequences:** Benefits, costs, and upgrade implications.

### ADR-005C: Manual CRM Lead Workspace Uses Additive VibeExe APIs

- **Date:** 2026-07-21
- **Status:** Accepted
- **Context:** Phase 5C needs a production lead workspace without overloading contacts, conversations, labels, or AI features.
- **Decision:** Add account-scoped VibeExe CRM APIs, services, routes, and UI screens for manual lead list/detail/board/settings while reusing Chatwoot contacts, conversations, users, teams, settings, table, dialog, selector, pagination, and shell patterns.
- **Consequences:** The workspace remains usable when AI is disabled and avoids new frontend dependencies. Existing upstream route/settings files are touched narrowly to mount additive CRM routes; future CRM import/export, saved filters, and custom-role work can extend the same namespace.
