---
name: chatwoot-architecture
description: Navigate Chatwoot Architecture
---

# Navigate Chatwoot Architecture


## Use when

Use this skill before implementing work in an unfamiliar Chatwoot area.

## Procedure

1. Search for the closest existing user flow and tests.
2. Trace routes, controllers, policies, services, models, serializers, jobs, stores, API clients, and UI components.
3. Identify the tenant boundary: installation, account, inbox, conversation, contact, or user.
4. Check feature flags, installation configuration, community/enterprise separation, and callbacks.
5. Map synchronous and asynchronous behavior, including webhooks and retries.
6. Summarize extension points and the minimum files likely to change.

## Output

Provide a concise architecture map, relevant paths, data flow, authorization boundary, likely tests, and upgrade-sensitive areas. Do not implement until the current flow is understood.
