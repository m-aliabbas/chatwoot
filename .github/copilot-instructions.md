# GitHub Copilot Instructions — VibeExe / Chatwoot

This repository is a maintainable Chatwoot Community Edition fork used to build VibeExe, a multi-tenant AI customer-engagement and CRM platform.

Before suggesting code:

1. Follow `AGENTS.md`.
2. Inspect nearby Chatwoot code and copy established patterns.
3. Prefer a narrow extension over replacing upstream behavior.
4. Preserve account isolation, authorization, i18n, accessibility, and upgradeability.
5. Do not invent APIs, models, feature flags, environment variables, or framework conventions. Search the repository first.

Backend guidance:

- Keep Rails controllers thin.
- Use policies and account-scoped queries.
- Put orchestration in services and slow external work in idempotent jobs.
- Add relevant RSpec coverage, including cross-account isolation for sensitive flows.
- Never log secrets, tokens, full message content, or unnecessary personal data.

Frontend guidance:

- Reuse existing Chatwoot components, stores, API clients, design tokens, and i18n.
- Avoid hard-coded brand colors and user-facing strings.
- Preserve loading, error, empty, responsive, and keyboard states.

VibeExe guidance:

- Use clear boundaries such as `VibeExe::Crm`, `VibeExe::Ai`, `VibeExe::Automation`, and `VibeExe::RealEstate` for genuinely new domains.
- Do not duplicate Chatwoot capabilities merely to create a namespace.
- Record meaningful upstream-file modifications in `docs/upstream-changes.md`.

When completing a change, report files changed, tests actually run, unresolved risks, and any upstream-sensitive modifications.

Do not modify Docker, Compose, environment, dependency, or database setup while
implementing product features. Keep infrastructure unchanged and report any
runtime steps separately. 