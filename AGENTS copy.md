# VibeExe / Chatwoot Repository Instructions

## Mission

This repository is a Chatwoot-based SaaS product named **VibeExe**. Chatwoot provides the messaging and inbox foundation. VibeExe adds product branding, CRM workflows, AI assistance, automation, analytics, and industry-specific modules.

The primary engineering objective is to ship useful VibeExe features while keeping the Chatwoot fork maintainable, secure, multi-tenant, and reasonably easy to upgrade.

## Working Principles

1. Understand the existing Chatwoot implementation before changing it.
2. Prefer extension over replacement.
3. Keep VibeExe-specific behavior isolated and clearly named.
4. Avoid broad refactors unless the task explicitly requires one.
5. Preserve account-level multi-tenancy in every query, job, API, and UI flow.
6. Never weaken authorization, authentication, auditability, or data isolation.
7. Reuse existing Chatwoot patterns, components, services, policies, and jobs.
8. Make the smallest complete change that solves the requested problem.
9. Add or update tests for meaningful behavior changes.
10. Document upgrade-sensitive changes.

## Repository Orientation

Before implementing a task:

1. Search for an existing feature with similar behavior.
2. Identify the relevant model, controller, service, policy, serializer, job, and frontend component.
3. Check whether the behavior is account-scoped, inbox-scoped, conversation-scoped, or user-scoped.
4. Check existing feature flags, installation configuration, and enterprise/community boundaries.
5. Read local instructions in nested `AGENTS.md` files and `.github/instructions/*.instructions.md`.

## Architecture Rules

### Backend

- Follow existing Ruby on Rails conventions in the repository.
- Keep controllers thin.
- Put orchestration and business logic in service objects or domain objects.
- Use policies/authorization checks consistently.
- Scope tenant data through the current account or another trusted tenant boundary.
- Avoid unscoped calls such as `Model.find`, `Model.where`, or global counts for tenant-owned records unless explicitly justified.
- Use transactions for multi-record state changes that must remain consistent.
- Use background jobs for slow, retryable, or external work.
- Make jobs idempotent where possible.
- Use existing serializers and API response conventions.
- Do not expose secrets, provider tokens, internal IDs, or sensitive metadata unnecessarily.

### Frontend

- Reuse the existing Chatwoot component library and design tokens before introducing new components.
- Preserve accessibility, keyboard navigation, responsive behavior, loading states, empty states, and error states.
- Keep API access in the established API/store layer rather than embedding requests in arbitrary components.
- Prefer focused components and composables over large page components.
- Do not hard-code brand colors where design tokens or CSS variables exist.
- Preserve localization. New user-facing strings must use the repository's i18n mechanism.

### VibeExe Modules

New VibeExe domain code should use a clear namespace or module boundary where practical, such as:

- `VibeExe::Ai`
- `VibeExe::Crm`
- `VibeExe::Automation`
- `VibeExe::Analytics`
- `VibeExe::RealEstate`

Do not create a parallel architecture when an existing Chatwoot abstraction is sufficient. Use namespacing to isolate genuinely new domain behavior, not to duplicate existing capabilities.

## Multi-Tenancy Checklist

For every VibeExe feature, verify:

- All tenant-owned records belong directly or indirectly to an account.
- Queries cannot return another account's data.
- IDs supplied by clients are re-scoped through the current account.
- Background jobs carry and validate the account context.
- Cache keys include tenant context where required.
- Search, exports, analytics, and AI retrieval remain tenant-isolated.
- Webhooks resolve the correct account/inbox using trusted identifiers.
- Tests include at least one cross-account isolation case for sensitive flows.

## AI Feature Rules

AI features must be assistive, observable, and safe.

- Keep provider-specific code behind adapters.
- Store prompts in dedicated prompt objects/files rather than large inline strings.
- Separate retrieval, prompt construction, model invocation, and output validation.
- Validate structured model output before use.
- Do not execute tool actions solely because a model requested them; enforce application authorization and business rules.
- Redact or minimize sensitive data sent to external providers.
- Record useful metadata such as provider, model, latency, status, and token usage without logging confidential content unnecessarily.
- Provide fallbacks and clear failure states.
- Avoid blocking request cycles on slow model calls when a job is more appropriate.

## WhatsApp and Meta Rules

- Never commit Meta app secrets, permanent access tokens, verification tokens, or phone credentials.
- Preserve webhook signature verification and idempotency.
- Treat webhook payloads as untrusted input.
- Avoid duplicate message creation when Meta retries events.
- Keep Embedded Signup configuration installation-scoped where appropriate.
- Do not mix customer WABA credentials across accounts.
- Maintain a clear separation between platform credentials and customer-connected business assets.
- Account for message status events, template states, media retrieval, rate limits, and token expiration.

## Branding Rules

The product name is **VibeExe**.

Preferred product style:

- Clean, modern, premium B2B SaaS.
- Primary blue family centered around `#2563EB`.
- Dark text around `#0F172A`.
- Light surfaces around `#F8FAFC`.
- Avoid scattered hard-coded branding strings and colors.

Brand changes should be implemented through configuration, constants, design tokens, assets, and reusable components where possible. Do not perform blind global text replacement because it can alter licenses, package names, APIs, or internal technical identifiers.

## Upgrade-Safety Rules

Classify changes as:

- **Low risk:** new isolated VibeExe files, configuration, tests, additive routes.
- **Medium risk:** targeted changes to stable Chatwoot extension points.
- **High risk:** changes to central inbox, message delivery, authentication, account scoping, shared stores, routing, or heavily modified upstream files.

For medium- and high-risk changes:

1. Keep the diff narrow.
2. Explain why an extension point was insufficient.
3. Add a note to `docs/upstream-changes.md`.
4. Include the upstream file path and purpose of the modification.
5. Add tests that capture the intended behavior.

Never delete upstream behavior merely to hide it. Prefer feature flags, configuration, permissions, navigation filtering, or VibeExe-specific presentation.

## Testing Expectations

Before claiming completion, run the smallest relevant checks available in the repository:

- Backend unit/request/service tests for changed behavior.
- Frontend unit/component tests where relevant.
- Linting or formatting for changed files.
- Database migration checks for schema changes.
- Manual verification notes for flows that are difficult to automate.

Do not claim tests passed unless they were actually executed. If execution is unavailable, state exactly what should be run.

## Database Changes

- Prefer additive and reversible migrations.
- Avoid long table locks and unsafe full-table rewrites.
- Add indexes for new foreign keys and frequent filters.
- Backfill large datasets using safe batches or jobs rather than one blocking migration.
- Use explicit nullability and defaults thoughtfully.
- Consider existing production data.

## Security Rules

- Never commit `.env` files or credentials.
- Do not log passwords, tokens, message bodies, attachments, or personal data without a clear need.
- Validate file type, size, and authorization for uploads/downloads.
- Preserve CSRF, CORS, rate limiting, webhook verification, and authorization controls.
- Treat all external payloads and AI output as untrusted.

## Task Execution Format

For substantial tasks, follow this sequence:

1. Summarize the requested behavior.
2. Identify relevant existing implementation.
3. State the proposed minimal design.
4. Implement in small coherent changes.
5. Add or update tests.
6. Report files changed, tests run, risks, and follow-up work.

## Definition of Done

A task is complete when:

- The requested behavior works.
- Tenant isolation and authorization are preserved.
- The change follows existing repository patterns.
- Relevant tests are added or updated.
- User-facing strings are localized.
- Secrets are not introduced.
- Upgrade-sensitive changes are documented.
- No unrelated refactor is included.
