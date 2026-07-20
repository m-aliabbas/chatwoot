---
name: code-review
description: Review VibeExe and Chatwoot Changes
---

# Review VibeExe and Chatwoot Changes


## Review order

1. Correctness and regressions
2. Authorization and tenant isolation
3. Secret handling and external-input validation
4. Data integrity, transactions, retries, and idempotency
5. Performance and query behavior
6. API compatibility and migrations
7. Frontend accessibility, i18n, and states
8. Test quality
9. Upstream upgrade risk

## Output

Rank findings as critical, high, medium, or low. Cite exact paths and lines. Explain the failure scenario and a concrete fix. Do not bury important findings in a general summary. If no material issue is found, state remaining test or verification gaps.
