# CRM Phase 5D: Lead Productivity

Phase 5D adds account-scoped notes, labels, tasks, follow-up scheduling, reminders, and a daily Tasks workspace around the existing lead domain. It remains independent of Captain/AI and conversation lifecycle state.

## Architecture

- `VibeExe::Crm::LeadNote` is the durable lead-note record. `LeadActivity` stores note lifecycle events, not note content as the source of truth.
- Lead notes and tasks reuse Active Storage for multiple account-authorized file and image attachments, subject to the installation upload-size limit.
- `VibeExe::Crm::Lead` reuses the account `Label` catalog through `Labelable`; no CRM-specific tag catalog is introduced.
- `VibeExe::Crm::Task` is the single persistent follow-up record. Types are follow-up, call, meeting, WhatsApp, email, general, and other. Statuses are pending, completed, and cancelled. Priorities are low, medium, high, and urgent.
- Overdue is computed for pending tasks whose `due_at` is in the past.
- A reminder is task metadata (`reminder_at` and `reminder_sent_at`), not a separate domain record.

## Lifecycle

Task create, update, completion, cancellation, and rescheduling use focused services. Meaningful changes append one event to `LeadActivity`. Completion and cancellation clear active reminder scheduling. Rescheduling clears delivery state so the new reminder can be delivered once.

## APIs

- Lead notes: `/api/v1/accounts/:account_id/vibeexe/crm/leads/:lead_id/notes`
- Lead tags: `/api/v1/accounts/:account_id/vibeexe/crm/leads/:lead_id/tags`
- Lead tasks: `/api/v1/accounts/:account_id/vibeexe/crm/leads/:lead_id/tasks`
- Task workspace: `/api/v1/accounts/:account_id/vibeexe/crm/tasks`
- Lifecycle actions: `/tasks/:id/complete`, `/tasks/:id/cancel`, and `/tasks/:id/reschedule`

All records are loaded through `Current.account`. Agents can update notes they authored and tasks they created or are assigned. Administrators can manage account-wide CRM productivity records.

## Migration

Run manually after review:

```sh
eval "$(rbenv init -)"
bundle exec rails db:migrate
```

Rollback is a standard single-step rollback; the additive migration drops only the Phase 5D task and note tables.

## Implementation Status

- 5D.1 schema, models, scopes, associations, and policies: implemented.
- 5D.2 lead note and tag APIs/services: implemented.
- 5D.3 task lifecycle services and APIs: implemented.
- 5D.4 lead-detail productivity UI: pending.
- 5D.5 Tasks workspace UI: implemented with agent-default worklist, search, filters, pagination, create/edit, completion, cancellation, lead navigation, overdue and due-today views.
- 5D.6 reminder delivery and notification UI: pending.
- 5D.7 focused tests, responsive polish, and final QA: pending.

Phase 5E concepts are intentionally excluded.
