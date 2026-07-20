---
name: chatwoot-upgrade-safety
description: Keep the Chatwoot Fork Upgradeable
---

# Keep the Chatwoot Fork Upgradeable


## Use when

Use this skill whenever modifying existing upstream Chatwoot files or replacing upstream behavior.

## Rules

- Prefer additive VibeExe files, configuration, feature flags, permissions, and composition.
- Avoid copying large upstream files into parallel implementations.
- Keep modifications to upstream files narrow and well tested.
- Never hide a feature by deleting unrelated upstream behavior.
- Preserve community/enterprise boundaries and licenses.

## Procedure

1. Classify the change as low, medium, or high merge risk.
2. Look for a configuration or extension point first.
3. If an upstream edit is necessary, explain why alternatives are insufficient.
4. Add an entry to `docs/upstream-changes.md`.
5. Add tests that express the VibeExe requirement independently of implementation details.
6. Review the diff for unnecessary formatting or refactoring noise.
