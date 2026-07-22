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
- 5D.4 lead-detail productivity UI: implemented with structured notes, note attachments, tags, task summaries, overdue/upcoming groupings, and task lifecycle actions.
- 5D.5 Tasks workspace UI: implemented with agent-default worklist, search, filters, pagination, create/edit, completion, cancellation, lead navigation, overdue and due-today views.
- Task lead selection uses a lazy, debounced server-backed autocomplete over lead title, contact name, and contact email; it does not preload the account's lead catalog.
- Task lifecycle UX includes optional completion notes, dedicated rescheduling, resolved reminder presets, overdue/upcoming lead groupings, and attachment indicators.
- The lead pipeline board supports persisted drag-and-drop stage movement, including empty stages, with rollback on API failure and the stage selector retained as an accessible fallback.
- 5D.6 reminder delivery and notification UI: implemented through the scheduled-items runner and the existing in-app notification feed. Delivery is assignee-only, pending-task-only, duplicate-safe, and does not send email or push notifications.
- 5D.7 focused tests and closure: backend request/job coverage added for task lifecycle, filtering, tenant isolation, notes, tags, permissions, reminder eligibility, recipient selection, and duplicate prevention. Static syntax and data-file checks pass; database-backed specs and manual responsive QA remain for the user to run.

## Closure Status

Phase 5D implementation is complete as of 2026-07-22. The code review found no material correctness, tenant-isolation, lifecycle, or upgrade-safety issue. Runtime acceptance remains dependent on the database-backed specs and manual QA below, which must be run by the user under the project's runtime boundary.

Phase 5E concepts are intentionally excluded.

## Final Manual Test Commands

```sh
eval "$(rbenv init -)"
bundle exec rspec \
  spec/controllers/api/v1/accounts/vibe_exe/crm/leads_controller_spec.rb \
  spec/controllers/api/v1/accounts/vibe_exe/crm/tasks_controller_spec.rb \
  spec/controllers/api/v1/accounts/vibe_exe/crm/lead_productivity_controller_spec.rb \
  spec/jobs/vibe_exe/crm/task_reminder_job_spec.rb

pnpm eslint \
  app/javascript/dashboard/routes/dashboard/vibeexe/leads/LeadWorkspace.vue \
  app/javascript/dashboard/routes/dashboard/vibeexe/leads/LeadTagPicker.vue \
  app/javascript/dashboard/routes/dashboard/vibeexe/tasks/LeadSelector.vue \
  app/javascript/dashboard/routes/dashboard/vibeexe/tasks/TaskWorkspace.vue \
  app/javascript/dashboard/api/vibeexeCrm.js
```

## Final Manual QA

- Verify lead list tag display and tag filtering with multiple labels.
- Verify open, overdue, and next-task indicators on lead detail.
- Verify My Tasks and All Tasks, lead/creator/status/type/priority/due filters, pagination, and search.
- Verify create, edit, complete with outcome note, cancel, and reschedule actions.
- Verify note/task file upload, download, and authorized removal.
- Verify reminder presets and one in-app delivery to the current assignee.
- Verify task-reminder navigation from both notification views.
- Check 1440px, 1280px, 1024px, 768px, and 390px layouts with no page-level horizontal overflow.
- Check keyboard focus, dialog Escape behavior, field labels, destructive confirmations, and non-color status text.
