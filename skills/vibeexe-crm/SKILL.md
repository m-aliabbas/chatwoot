---
name: vibeexe-crm
description: Build VibeExe CRM Modules
---

# Build VibeExe CRM Modules


## Scope

Use for leads, deals, properties, activities, assignments, pipelines, notes, commissions, and real-estate workflows.

## Domain rules

- Reuse Chatwoot contacts, conversations, inboxes, users, teams, labels, and custom attributes where they fit.
- Create new models only for durable domain concepts that cannot be represented cleanly by existing primitives.
- Every tenant-owned record must belong directly or indirectly to an account.
- Keep product-neutral CRM concepts separate from optional real-estate specialization.

## Procedure

1. Define actors, lifecycle, invariants, permissions, and account ownership.
2. Map reusable Chatwoot entities and identify genuinely new entities.
3. Design additive schema with indexes, constraints, and safe migrations.
4. Define service boundaries and events for automation.
5. Build account-scoped APIs and policies.
6. Add UI using existing Chatwoot components and navigation patterns.
7. Test cross-account access, assignment permissions, lifecycle transitions, and destructive actions.
