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

### ADR-005D: CRM Productivity Uses First-Class Notes and Tasks with Shared Labels

- **Date:** 2026-07-22
- **Status:** Accepted
- **Context:** Lead follow-up needs durable notes, assignable work, reminders, and tags without coupling leads to conversations or Captain tasks.
- **Decision:** Add account-scoped `LeadNote` and `Task` models, store reminder delivery state on tasks, reuse account labels through `Labelable`, and publish lifecycle events through `LeadActivity`.
- **Consequences:** CRM productivity works with AI disabled and retains tenant-safe query paths. Reminder delivery can be added through a small scheduled job without creating a second reminder domain or changing conversation snooze behavior.
