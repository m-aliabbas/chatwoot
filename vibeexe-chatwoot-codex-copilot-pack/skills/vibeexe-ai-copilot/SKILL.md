---
name: vibeexe-ai-copilot
description: Build the VibeExe AI Copilot
---

# Build the VibeExe AI Copilot


## Scope

Use for reply suggestions, summaries, customer memory, retrieval, next-best actions, lead qualification, and AI-assisted workflows.

## Architecture

Separate:

1. tenant-scoped data retrieval,
2. prompt/context construction,
3. provider adapter invocation,
4. structured output validation,
5. authorized application actions,
6. observability and feedback.

## Safety rules

- Never trust model output or let it bypass policies.
- Minimize external data exposure.
- Do not silently send messages or mutate CRM data unless the product flow explicitly authorizes it.
- Make suggestions distinguishable from confirmed facts.
- Record provider/model/latency/token metadata while avoiding unnecessary raw confidential content.

## Testing

Test tenant isolation, permission enforcement, malformed output, provider failure, retries, timeout behavior, and deterministic tool business rules.
