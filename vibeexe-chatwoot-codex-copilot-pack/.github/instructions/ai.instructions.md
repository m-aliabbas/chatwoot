---
applyTo: "app/**/*ai*,app/**/*copilot*,lib/**/*ai*,spec/**/*ai*,prompts/**/*"
---

# AI Feature Instructions

- Keep providers behind adapters.
- Separate retrieval, prompt construction, invocation, validation, and tool execution.
- Treat model output as untrusted input.
- Validate structured output before saving or acting.
- Enforce normal application authorization for every AI-triggered action.
- Minimize/redact data sent to external providers.
- Track provider, model, latency, status, and token usage without unnecessary confidential content.
- Use jobs for slow calls and provide useful failure/fallback states.
- Test prompt-independent business rules and tool authorization deterministically.
