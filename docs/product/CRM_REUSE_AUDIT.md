# VibeExe CRM Reuse Audit

## 1. Executive summary

Phase 5A should reuse Chatwoot as the communication, identity, account, team, assignment, tagging, notes, import/export, and filtering foundation, but it should not turn support conversations or contact metadata into the CRM domain itself.

The recommended architecture is additive: keep `Account`, `Contact`, `Conversation`, `User`, `AccountUser`, `Team`, `Inbox`, `Label`, custom attributes, contact notes, private messages, search, and channel integrations as shared platform capabilities, then introduce first-class VibeExe CRM models for durable sales concepts such as leads, pipelines, stages, tasks, property requirements, property matches, site visits, deals, commissions, and audit/history.

The most important domain decision is that one Chatwoot contact can safely have many VibeExe leads. A contact represents a person or customer identity within an account; a lead represents a sales opportunity or intent for that person. Multiple active or historical leads are valid when the same person is interested in different properties, projects, budgets, timelines, or deal cycles.

## 2. Existing Chatwoot capabilities to reuse

- Account tenancy: `Account` owns contacts, conversations, users through account users, teams, labels, custom filters, custom attributes, data imports, notes, messages, inboxes, and enterprise companies.
- Contacts: `Contact` already stores account-scoped person identity, name, email, phone number, identifier, avatar, country, custom attributes, additional attributes, labels, notes, contact inboxes, conversations, and contact merge behavior.
- Contact identities: `ContactInbox` maps one contact to one inbox/source identity with a unique `(inbox_id, source_id)` constraint and is the right bridge for WhatsApp, email, website, API, SMS, and social channel identities.
- Conversations: `Conversation` already belongs to account/contact/contact inbox/inbox, has status, priority, assignee, team, labels, custom attributes, messages, participants, reporting events, and unread/filter infrastructure.
- Assignment: conversation assignment reuses `User` for human assignees and validates account membership through `conversation.account.users`; teams are account-scoped and can auto-assign conversation assignees.
- Account users and memberships: `AccountUser` is the account membership, role, availability, custom role, capacity policy, and notification settings boundary.
- Teams: `Team` and `TeamMember` provide account-scoped grouping and membership.
- Labels and tags: `Label` is account-scoped and backed by `acts-as-taggable-on` for contacts and conversations.
- Custom attributes: `CustomAttributeDefinition` supports contact, conversation, and company attributes with typed display definitions and filtering.
- Private notes and messages: `Note` is contact-scoped; `Message` supports `private: true` plus activity messages within conversations.
- Search/filtering: `SearchService`, `ConversationFinder`, `Contacts::FilterService`, `Conversations::FilterService`, and `CustomFilter` provide reusable search, saved segment, folder, and advanced filter patterns.
- Contact import/export: legacy contact CSV import uses `DataImport`, `DataImportJob`, and `DataImport::ContactManager`; contact export uses `Account::ContactsExportJob`.
- Background import framework: newer `data_imports` supports Intercom-style long-running imports with status, items, mappings, errors, skip logs, restart/abandon controls, and CSV log downloads.
- Duplicate handling: contact uniqueness and merge behavior already exist around account-scoped email, phone number, identifier, contact inbox source identity, CSV import matching, and `ContactMergeAction`.
- Enterprise companies: `Company` is enterprise-only and feature-gated; contacts can belong to one company and company records support custom attributes, search, notes/history views, avatar, contacts count, and activity rollup.
- Audit logs: Enterprise uses the `audited` gem through `Enterprise::AuditLog` and `Enterprise::Audit::*` concerns for selected account, team, inbox, user, macro, automation, and conversation destroy events.
- Frontend shell: Phase 4 VibeExe routes already expose `leads_index` and `tasks_index` as placeholder modules behind the CRM/module shell.
- Frontend list/detail patterns: contacts and companies use `components-next` list layouts, detail layouts, sidebars, tab bars, dialogs, pagination, search, sorting, bulk actions, custom attributes, notes, history, merge, and contact-company membership patterns.

## 3. Capabilities that should not be overloaded

- Do not use `Contact.contact_type = lead` as the VibeExe lead model. It is a coarse contact classification and cannot represent multiple pipelines, stages, owners, budgets, requirements, conversations, site visits, deals, or lead history.
- Do not store pipeline stage, lead status, owner, expected value, deal probability, property requirement, site visit, commission, or next-task state only in contact or conversation custom attributes. These values need constraints, indexes, lifecycle transitions, reporting, and history.
- Do not treat `Conversation.status` as lead lifecycle. Conversation status is a support/inbox workflow with open/resolved/pending/snoozed semantics.
- Do not treat conversation `assignee_id` as lead ownership. Conversation assignment can change for support coverage and auto-assignment; lead ownership is CRM accountability.
- Do not stretch `Label` into pipeline stages or required CRM statuses. Labels are useful tags, not ordered state machines.
- Do not use contact notes or private messages as a substitute for structured lead activities or tasks.
- Do not overload Enterprise `Company` into property developers, property inventory, agencies, or deal parties without a clear company-contact business relationship.
- Do not rely on the existing audit log as the only CRM timeline. Audit logs are Enterprise-gated and mostly administrative, while CRM activity must be product-visible and available for lead workflows.

## 4. Missing CRM capabilities

- First-class leads with owner, team, source, pipeline, stage, value, priority, status, close/lost reasons, expected close date, and timestamps.
- Account-scoped pipelines and ordered stages.
- Many-to-many lead-conversation links.
- Lead activity timeline independent of support messages.
- Tasks and reminders with due dates, completion state, assignee/owner, related lead/contact/conversation, and notification hooks.
- Real-estate-specific requirements, properties, property matches, site visits, deals, and commissions.
- CRM-specific duplicate lead detection and possible duplicate review workflow.
- CRM import/export mappings, validations, preview, row-level errors, and logs.
- CRM authorization policies, custom role permissions, scopes, and cross-account isolation tests.
- CRM reporting/search indexes and saved views.
- CRM audit/change history for important lifecycle changes.

## 5. Recommended domain model

Core CRM:

- `Lead`
- `Pipeline`
- `PipelineStage`
- `LeadConversation`
- `LeadActivity`
- `Task`
- `Reminder`

Real-estate specialization:

- `Requirement`
- `Property`
- `PropertyMatch`
- `SiteVisit`
- `Deal`
- `Commission`

History:

- `AuditEvent` or a CRM-specific audited concern, depending on whether CRM audit history must be available in community installations.

Recommended ownership:

- Every tenant-owned CRM record should belong directly to `Account`.
- Every lead should belong to `Contact`.
- Lead owner should reference `User` with validations/scopes through `AccountUser`.
- Use `AccountUser` for membership/role/permission checks and `User` for the owner foreign key, matching conversation assignment and existing UI agent selectors.

## 6. Proposed relationships

```text
Account
  has many leads, pipelines, pipeline stages, lead activities, tasks, reminders
  has many properties, property matches, site visits, deals, commissions

Contact
  has many leads
  has many conversations
  has many contact inboxes
  optionally belongs to enterprise company

Lead
  belongs to account
  belongs to contact
  belongs to pipeline
  belongs to pipeline_stage
  belongs to owner, class_name: "User", optional: true
  belongs to team, optional: true
  has many lead_conversations
  has many conversations, through: lead_conversations
  has many lead_activities
  has many tasks
  has many reminders, through tasks or directly if needed
  has many requirements
  has many property_matches
  has many site_visits
  has one deal

LeadConversation
  belongs to account
  belongs to lead
  belongs to conversation

Task
  belongs to account
  belongs to lead, optional: true
  belongs to contact, optional: true
  belongs to conversation, optional: true
  belongs to assignee, class_name: "User", optional: true
```

## 7. Account-scoping strategy

All CRM records should carry `account_id` directly, even when account could be inferred through lead/contact/conversation. This follows Chatwoot's hot-path tenant checks and makes policy scopes, joins, imports, exports, reporting, and cleanup straightforward.

Controllers should load records through `Current.account`, for example `Current.account.leads.find(params[:id])`. Join models such as `LeadConversation` should validate that the lead, conversation, and contact all belong to the same account. Any owner or assignee should be validated through `Current.account.users` or `account.users`.

## 8. Authorization strategy

Use Pundit, matching `ApplicationPolicy`, `ContactPolicy`, `ConversationPolicy`, `CustomFilterPolicy`, and `DataImportPolicy`.

Recommended pattern:

- `LeadPolicy::Scope` returns `account.leads`, further filtered by custom role permissions when Enterprise custom roles are present.
- Admins can create, update, destroy, import, export, and manage pipeline configuration.
- Agents can view and update leads when they have CRM/contact permission, are the lead owner, are on the lead team, or have an eventual CRM custom-role permission.
- Destructive operations should be admin-only until CRM-specific permissions are defined.
- Enterprise custom roles should receive additive CRM permissions rather than reusing conversation permissions for CRM behavior.

## 9. Lead assignment strategy

Lead owner should reference `User`, not `AccountUser`, because existing assignment UI, conversation assignment, mentions, messages, notifications, and serializers generally expose users as actors. However, every assignment must validate account membership through `AccountUser` or `account.users`.

Teams can be reused as optional lead teams. Do not reuse conversation auto-assignment directly for lead ownership in Phase 5B. Lead assignment may later borrow team membership selectors and capacity concepts, but CRM ownership should remain independent from inbox load balancing.

## 10. Contact-to-lead relationship

One Chatwoot contact can safely have multiple VibeExe leads. Contact identity is account-person identity; lead identity is sales opportunity identity.

Use the existing contact as the canonical person record for name, phone, email, identifiers, channel identities, contact-level labels, notes, and conversations. Use leads for opportunity state: pipeline, stage, owner, budget, source, requirements, expected value, timeline, deal, commission, and lead-specific tags/activities.

## 11. Conversation-to-lead linking strategy

Add `LeadConversation` as an explicit account-scoped join. A lead can have many conversations and a conversation can be linked to multiple leads if the same customer thread spans different opportunities.

Default linking can be suggested by matching `lead.contact_id == conversation.contact_id`, but it should not be implicit forever. Agents need the ability to attach or detach a conversation from a lead because one contact may discuss multiple deals over time.

## 12. Duplicate-detection strategy

Reuse existing contact duplicate signals:

- `contacts.email` unique per account, case-insensitive.
- `contacts.phone_number` unique per account after E.164 normalization.
- `contacts.identifier` unique per account.
- `contact_inboxes` unique per inbox/source identity.
- `DataImport::ContactManager` lookup order of identifier, email, then phone.
- `ContactMergeAction` for confirmed contact merges.

Add CRM lead duplicate detection separately. Suggested duplicate lead candidates:

- Same account and contact.
- Same pipeline or active stage group.
- Similar requirements, budget range, project/property interest, source, and active/open state.
- Same normalized external lead id when imported.
- Conversation-derived candidates only as suggestions, not hard uniqueness, because one contact may legitimately have multiple leads.

Confirmed contact merges must reassign or reconcile associated leads. Lead merges should be separate from contact merges.

## 13. Tags and custom-attribute strategy

Labels can safely represent lead tags if CRM leads become taggable with the same account-owned `Label` catalog. This keeps filtering, color/title management, and UI familiarity consistent.

Use custom attributes for optional, low-cardinality, non-critical enrichment:

- Secondary source metadata.
- Campaign hints.
- UTM/source details.
- External CRM IDs that are not primary join keys.
- Freeform preferences.
- Optional qualification answers.

Use first-class columns for values that need constraints, ordering, reporting, indexes, permissions, lifecycle rules, or frequent filters:

- `account_id`, `contact_id`, `pipeline_id`, `pipeline_stage_id`.
- `owner_id`, `team_id`.
- Lead status/lifecycle, priority, source, value/budget, expected close date.
- Lost/won state and reason.
- Task due date, completion state, assignee, reminder state.
- Property/deal/commission amounts, statuses, and dates.

## 14. Activity and task strategy

Reuse contact notes and private messages for human-readable context, but create `LeadActivity` for CRM timeline events. Conversation activity messages are tied to conversation state changes and should not become the CRM event ledger.

No existing general-purpose task/reminder model is suitable for CRM reuse. Conversation snooze and notification snooze are support/notification states, not assignable CRM tasks. Captain tasks are AI service endpoints behind `captain_tasks`, not persistent agent task records.

Recommended activity sources:

- Lead created, stage changed, owner changed, team changed.
- Conversation linked/unlinked.
- Note added.
- Task created/completed/overdue.
- Requirement changed.
- Property matched/rejected.
- Site visit scheduled/completed.
- Deal won/lost.
- Commission recorded/paid.

## 15. Import/export reuse plan

Reuse:

- `DataImport` status model and attachment/log concepts.
- `DataImportItem`, `DataImportMapping`, and `DataImportError` patterns for integration imports.
- CSV normalization, BOM handling, row-level rejection, failed-record export, and notification patterns from `DataImportJob`.
- Contact matching from `DataImport::ContactManager`.
- CSV export shape from `Account::ContactsExportJob`.
- Data Imports settings UI patterns for long-running jobs, polling, summary tiles, error logs, skip logs, and source validation.

Add:

- CRM-specific import services for leads, tasks, requirements, and properties.
- CRM-specific mapping and validation rules.
- Preview/dry-run behavior before mutating leads, if product requires human confirmation.
- Export jobs for leads and related CRM records.

## 16. Audit-history strategy

Use two layers:

- Product timeline: `LeadActivity` for user-visible CRM events and notes. This should exist in community and enterprise editions.
- Compliance audit: Enterprise can additionally use `audited` via `Enterprise::Audit::*` concerns for administrative/security-grade changes.

If CRM audit history must be visible in community, create `AuditEvent` under the VibeExe CRM domain instead of relying solely on Enterprise `Enterprise::AuditLog`.

## 17. Frontend components and patterns to reuse

Reuse:

- `VibeExePageShell` and existing `leads_index` / `tasks_index` route slots.
- Contacts list/detail layouts and components under `components-next/Contacts`.
- Companies list/detail layouts and components under `components-next/Companies` where Enterprise/company context applies.
- `components-next/table/BaseTable*`, `components/table/Table.vue`, and table footer/pagination widgets.
- `components-next/filter/ContactsFilter.vue`, `ConversationFilter.vue`, active filter preview, saved custom views, and filter query generation patterns.
- Contact segments through `CustomFilter` with `filter_type: contact` as a pattern for future lead saved views.
- Dialog, tab bar, select, checkbox, input, button, and spinner components from `components-next`.
- Contact import/export dialogs as UX references.
- Data import settings pages for long-running import monitoring.
- Conversation cards/list patterns for linked-conversation previews.
- Contact notes/history/custom attribute sidebars as lead detail sidebar references.

Board-style UI:

- No first-class Kanban board component was found in the inspected paths.
- Phase 5B should build an additive lead board using existing cards, drag/drop if already present elsewhere, and pipeline/stage APIs, rather than reshaping conversation lists into a pipeline board.

## 18. Community versus Enterprise boundaries

Community-safe CRM foundation:

- Leads, pipelines, stages, lead conversations, activities, tasks, reminders, requirements, properties, property matches, site visits, deals, commissions.
- Account/contact/conversation/user/team/label/custom attribute reuse.
- Product-visible lead activity timeline.
- CRM import/export.

Enterprise-only or Enterprise-aware:

- Companies are currently Enterprise-gated through the `companies` feature and installation type checks.
- Audit logs are Enterprise premium via `audit_logs`.
- Custom roles and advanced conversation permissions are Enterprise.
- SLA, advanced assignment/capacity, voice calls, advanced search, and Captain features may enrich CRM but should not be required for the community CRM core.

Phase 5B should keep CRM core additive in OSS-compatible paths unless the product explicitly chooses Enterprise-only placement. Enterprise-specific extensions should use `prepend_mod_with` / `include_mod_with` rather than hard forking core files.

## 19. Upgrade-sensitive areas

- `Contact.contact_type` and `crm_v2` are existing upstream CRM-ish concepts; do not assume they mean VibeExe leads.
- `Contact` uniqueness and merge behavior are critical and should not be weakened.
- `ConversationFinder`, `Conversations::PermissionFilterService`, unread count invalidation, and conversation assignment are hot support paths.
- `Label` renaming updates associated taggable models through background jobs.
- `CustomAttributeDefinition::STANDARD_ATTRIBUTES` and filter YAML drive saved filters and advanced filters.
- Enterprise `Company` overlays modify `Contact` behavior and contact payloads when the companies feature is enabled.
- `DataImport` is expanding for Intercom imports; CRM imports should compose with the framework rather than rewriting it.
- Existing VibeExe shell changes touched sidebar/routes; lead/task routes should remain additive and feature-gated.
- `docs/upstream-changes.md` should be updated only when Phase 5B changes existing upstream files.

## 20. Phase 5B implementation plan

1. Define CRM feature flags and permissions: decide whether `crm` gates all CRM modules and add CRM-specific custom-role permissions if needed.
2. Add schema in small slices: pipelines/stages, leads, lead conversations, lead activities, then tasks/reminders.
3. Add model validations and account consistency checks for every association.
4. Add Pundit policies and policy scopes before controllers.
5. Add serializers/Jbuilder views following account-scoped API patterns.
6. Add APIs under `api/v1/accounts/:account_id` without changing existing contact/conversation contracts.
7. Add lead list and detail UI using `VibeExePageShell`, `components-next`, existing filters, labels, custom attributes, contact selector, owner/team selectors, notes/activity/sidebar patterns.
8. Add explicit conversation linking UI from lead detail and conversation sidebar.
9. Add duplicate candidate service and UI warnings, but allow legitimate multiple leads per contact.
10. Add CRM import/export as a separate service/job family reusing data import status/log patterns.
11. Add product activity timeline events and optional Enterprise audit concerns.
12. Add targeted specs for tenant isolation, owner/team validation, lead-conversation account consistency, authorization, duplicate detection, and import row handling.

## 21. Open architecture decisions

- Should VibeExe CRM ship in community paths by default or be Enterprise-gated?
- Should `Company` be reused when Enterprise companies are enabled, or should CRM introduce a community-safe organization/account entity later?
- What exact lead statuses are separate from pipeline stages?
- Can a lead belong to multiple pipelines over time, or should pipeline changes create historical activity only?
- Should lead tags reuse the global account `Label` namespace or use CRM-specific tag namespaces?
- Which custom role permissions should CRM add beyond `contact_manage`?
- Should tasks support polymorphic ownership across lead/contact/conversation/property, or start lead-first?
- Should reminders be separate records or scheduled task fields in Phase 5B?
- Which imports are required first: CSV leads, CSV contacts+leads, Intercom-to-leads, or real-estate property imports?
- Which fields define a duplicate lead candidate strongly enough to warn versus block?
- Should lead activity timeline include selected conversation activity messages, or only explicit lead events?
- Should CRM audit history be community-visible via `LeadActivity`/`AuditEvent`, Enterprise-only via `audited`, or both?

## Files inspected

- `.agents/skills/chatwoot-architecture/SKILL.md`
- `.agents/skills/chatwoot-feature-development/SKILL.md`
- `.agents/skills/chatwoot-upgrade-safety/SKILL.md`
- `.agents/skills/vibeexe-crm/SKILL.md`
- `.agents/skills/code-review/SKILL.md`
- `app/models/account.rb`
- `app/models/account_user.rb`
- `app/models/contact.rb`
- `app/models/contact_inbox.rb`
- `app/models/conversation.rb`
- `app/models/custom_attribute_definition.rb`
- `app/models/custom_filter.rb`
- `app/models/data_import.rb`
- `app/models/label.rb`
- `app/models/message.rb`
- `app/models/note.rb`
- `app/models/reporting_event.rb`
- `app/models/team.rb`
- `app/models/team_member.rb`
- `app/models/concerns/activity_message_handler.rb`
- `app/models/concerns/assignment_handler.rb`
- `app/models/concerns/auto_assignment_handler.rb`
- `app/actions/contact_merge_action.rb`
- `app/controllers/api/v1/accounts/base_controller.rb`
- `app/controllers/api/v1/accounts/contacts_controller.rb`
- `app/controllers/api/v1/accounts/contacts/labels_controller.rb`
- `app/controllers/api/v1/accounts/contacts/notes_controller.rb`
- `app/controllers/api/v1/accounts/conversations_controller.rb`
- `app/controllers/api/v1/accounts/conversations/assignments_controller.rb`
- `app/controllers/api/v1/accounts/conversations/labels_controller.rb`
- `app/controllers/api/v1/accounts/custom_filters_controller.rb`
- `app/controllers/api/v1/accounts/data_imports_controller.rb`
- `app/controllers/api/v1/accounts/search_controller.rb`
- `app/controllers/api/v1/accounts/actions/contact_merges_controller.rb`
- `app/finders/conversation_finder.rb`
- `app/jobs/account/contacts_export_job.rb`
- `app/jobs/data_import_job.rb`
- `app/policies/application_policy.rb`
- `app/policies/contact_policy.rb`
- `app/policies/conversation_policy.rb`
- `app/policies/custom_filter_policy.rb`
- `app/policies/data_import_policy.rb`
- `app/services/contact_inbox_source_id_resolver.rb`
- `app/services/contacts/filter_service.rb`
- `app/services/conversations/assignment_service.rb`
- `app/services/conversations/filter_service.rb`
- `app/services/conversations/permission_filter_service.rb`
- `app/services/data_import/contact_manager.rb`
- `app/services/filter_service.rb`
- `app/services/search_service.rb`
- `config/routes.rb`
- `docs/upstream-changes.md`
- `docs/architecture-decisions.md`
- `enterprise/app/models/company.rb`
- `enterprise/app/models/enterprise/audit/conversation.rb`
- `enterprise/app/models/enterprise/audit_log.rb`
- `enterprise/app/models/enterprise/concerns/account.rb`
- `enterprise/app/models/enterprise/concerns/contact.rb`
- `enterprise/app/controllers/api/v1/accounts/audit_logs_controller.rb`
- `enterprise/app/controllers/api/v1/accounts/companies_controller.rb`
- `enterprise/app/controllers/api/v1/accounts/companies/contacts_controller.rb`
- `enterprise/app/controllers/api/v1/accounts/companies/notes_controller.rb`
- `enterprise/app/policies/company_policy.rb`
- `enterprise/app/services/companies/contact_membership_service.rb`
- `enterprise/app/services/contacts/company_association_service.rb`
- `enterprise/app/services/enterprise/conversations/permission_filter_service.rb`
- `enterprise/app/services/enterprise/search_service.rb`
- `app/javascript/dashboard/featureFlags.js`
- `app/javascript/dashboard/constants/permissions.js`
- `app/javascript/dashboard/vibeexe/modules.js`
- `app/javascript/dashboard/routes/dashboard/vibeexe/vibeexe.routes.js`
- `app/javascript/dashboard/routes/dashboard/vibeexe/VibeExeEmptyModulePage.vue`
- `app/javascript/dashboard/routes/dashboard/contacts/routes.js`
- `app/javascript/dashboard/routes/dashboard/contacts/pages/ContactsIndex.vue`
- `app/javascript/dashboard/routes/dashboard/contacts/pages/ContactManageView.vue`
- `app/javascript/dashboard/routes/dashboard/companies/routes.js`
- `app/javascript/dashboard/routes/dashboard/companies/pages/CompaniesIndex.vue`
- `app/javascript/dashboard/routes/dashboard/companies/pages/CompanyDetailView.vue`
- `app/javascript/dashboard/routes/dashboard/settings/data/Index.vue`
- `app/javascript/dashboard/routes/dashboard/settings/data/Show.vue`
- `app/javascript/dashboard/routes/dashboard/settings/data/NewImportDialog.vue`
- `app/javascript/dashboard/routes/dashboard/customviews/DeleteCustomViews.vue`
- `app/javascript/dashboard/components-next/Contacts`
- `app/javascript/dashboard/components-next/Companies`
- `app/javascript/dashboard/components-next/filter`
- `app/javascript/dashboard/components-next/table`
- `app/javascript/dashboard/components/widgets/conversation`
- `app/javascript/dashboard/modules/search`
