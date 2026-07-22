# CRM Phase 5C: Lead Workspace and Pipeline UI

Phase 5C replaces the Leads placeholder with a manual CRM workspace that works without AI services.

## Routes

- Frontend list and board: `/app/accounts/:accountId/leads`
- Frontend lead detail: `/app/accounts/:accountId/leads/:leadId`
- Frontend pipeline settings: `/app/accounts/:accountId/settings/crm/pipelines`
- API lead CRUD: `/api/v1/accounts/:account_id/vibeexe/crm/leads`
- API lead detail actions: `archive`, `restore`, `mark_won`, `mark_lost`, `change_stage`
- API lead sections: `/leads/:lead_id/conversations`, `/leads/:lead_id/activities`
- API board: `/leads/board?pipeline_id=:id`
- API pipeline settings: `/pipelines`, `/pipelines/bootstrap_default`, `/pipelines/:pipeline_id/stages`
- Inbox defaults remain under inbox settings and now include an optional default stage.

## Screens

- Lead list with search, filters, pagination, sorting parameters, empty/loading/error states, and create action.
- Lead create/edit dialog with contact, title, pipeline, stage, owner, team, source, priority, value, currency, expected close date, and lost reason.
- Lead detail page with overview, duplicate warnings, linked conversations, activity timeline, note creation, lifecycle actions, and sidebar fields.
- Pipeline board grouped by active stages for one pipeline. Cards can be opened and moved through a stage selector.
- CRM pipeline settings for pipelines, stages, lifecycle stage type, probability, activation, deletion safeguards, and explicit default pipeline bootstrap.

## Filters

Lead list and board APIs support:

- Search query
- Pipeline
- Stage
- Owner
- Team
- Priority
- Status
- Source
- Created date lower/upper bounds
- Expected close date lower/upper bounds

## Lifecycle

- Manual create records `lead_created`.
- Updates record `pipeline_changed`, `stage_changed`, `owner_changed`, `team_changed`, or `status_changed` when those fields change.
- Won/lost/archive/restore actions use `VibeExe::Crm::TransitionLeadService`.
- Moving into a won/lost stage updates lead status and closed fields.
- Linked/unlinked conversations continue to use `LeadConversation` and `LeadActivity`; no second event ledger was introduced.

## Pipeline Rules

- Pipeline and stage records are account-scoped.
- Active pipelines and stages are the only options returned by the standard pipeline selector API.
- Deletion is blocked when leads or inbox defaults depend on a pipeline or stage.
- Active pipelines cannot lose their last active open stage through stage update/delete.
- The default sales pipeline bootstrap is explicit, idempotent, account-scoped, and admin-only.

## Duplicate Warnings

Warnings are non-blocking and currently surface:

- Same-contact open leads
- Same-contact same-pipeline candidates
- Matching external ID candidates when `metadata.external_id` exists

Agents can open existing leads from the warning area. No automatic merge behavior is included.

## Permissions

- Lead access uses the existing Phase 5B `LeadPolicy`: administrators and agents can view/create/update lifecycle/link actions.
- Pipeline and stage administration uses `PipelinePolicy`: administrators only.
- All API lookups use `Current.account` and return not found for cross-account records.

## Responsive Behavior

- The lead list is horizontally scrollable only inside the table area.
- The detail sidebar stacks under content on narrower screens.
- The board uses intentional horizontal stage scrolling.
- Primary actions remain in the header/action rows on narrow layouts.
- The lead toolbar separates primary filters from a responsive More Filters popover and keeps list/board selection beside the primary create action.
- Create/edit forms use the accessible components-next dialog, switch to one column on small screens, and keep their body vertically bounded.

## Workspace UI

- Lead rows prioritize lead, contact, stage, owner, priority, status, value, activity, and created date; secondary pipeline and source context appears under the lead title.
- `VibeExeCrmBadge` provides text-labelled status, priority, stage, and conversation-state treatments; `VibeExeDetailField` provides consistent structured values and intentional empty states.
- Lead lifecycle actions use focused lost and archive confirmation dialogs. Lost reason is only collected when the lead is marked lost.
- Linked conversations use structured message rows, while lead events and notes use a chronological activity timeline.
- Pipeline settings use labelled controls, selected-pipeline affordances, and responsive stage rows while preserving existing API behavior.

## Accessibility Decisions

- Filters and form selectors have visible labels and meaningful empty options.
- Native components-next dialogs retain keyboard focus management and Escape behavior; destructive actions require confirmation.
- Badges include readable text and do not communicate state by color alone.
- Loading and error states expose status and alert roles, and lead links retain visible keyboard focus.

## Manual Commands

The user should run these manually after reviewing the change:

```sh
eval "$(rbenv init -)"
bundle exec rails db:migrate
bundle exec rspec spec/controllers/api/v1/accounts/vibe_exe/crm/leads_controller_spec.rb spec/controllers/api/v1/accounts/vibe_exe/crm/pipelines_controller_spec.rb spec/controllers/api/v1/accounts/vibe_exe/crm/conversation_leads_controller_spec.rb
pnpm eslint app/javascript/dashboard/api/vibeexeCrm.js app/javascript/dashboard/routes/dashboard/vibeexe/leads/LeadWorkspace.vue app/javascript/dashboard/routes/dashboard/vibeexe/vibeexe.routes.js app/javascript/dashboard/routes/dashboard/settings/crm/CrmPipelineSettings.vue app/javascript/dashboard/routes/dashboard/settings/crm/crm.routes.js app/javascript/dashboard/routes/dashboard/settings/settings.routes.js app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/CrmLeadConfigurationPage.vue app/javascript/dashboard/routes/dashboard/conversation/components/LinkedLeadSection.vue
```

## Manual QA Checklist

- Enable CRM for a test account.
- Open Leads and verify empty, loading, and error states as practical.
- Open CRM pipeline settings and create the default sales pipeline.
- Create a manual lead from an existing contact.
- Search, filter, paginate, and sort the lead list.
- Open lead detail from the list and from a conversation sidebar linked lead.
- Edit core lead fields, owner, team, pipeline, and stage.
- Mark the lead won, lost with a reason, archived, and restored.
- Link and unlink same-contact conversations.
- Add an activity note and verify activity ordering.
- Open board view, move a card to another stage, and verify status changes for won/lost stages.
- Configure inbox CRM defaults, including a default stage.
- Verify the workspace loads and functions with AI/Captain disabled.
- Check 1440px, 1024px, 768px, and 390px widths.

## Remaining Gaps

- Drag-and-drop was intentionally not added to avoid a new frontend dependency.
- Saved advanced lead filters are not implemented.
- Full RBAC redesign and CRM-specific custom roles remain out of scope.
- Tasks, reminders, properties, site visits, deals, imports/exports, automation, reporting, and AI qualification remain out of scope for Phase 5C.
