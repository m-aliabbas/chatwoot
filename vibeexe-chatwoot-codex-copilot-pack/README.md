# VibeExe Chatwoot Agent Pack

Repository instructions and reusable skills for Codex and GitHub Copilot while building VibeExe on top of Chatwoot Community Edition.

## What is included

- `AGENTS.md` — primary repository constitution for Codex and coding agents.
- `.agents/skills/<skill>/SKILL.md` — standard agent skill layout.
- `skills/<skill>/SKILL.md` — visible mirror for archive viewers that hide dot-folders.
- `.github/copilot-instructions.md` — repository-wide GitHub Copilot instructions.
- `.github/instructions/*.instructions.md` — path-specific Copilot rules.
- `docs/architecture-decisions.md` — lightweight ADR log.
- `docs/upstream-changes.md` — records modifications to upstream Chatwoot files.
- `docs/task-prompts.md` — ready-to-use Codex prompts.

## Installation

Copy the **contents** of this folder into the root of your Chatwoot fork:

```bash
cp -R vibeexe-chatwoot-codex-copilot-pack/. /path/to/chatwoot/
```

On macOS Finder, hidden folders may not appear. Press `Cmd + Shift + .` to show them.

Commit the instruction pack:

```bash
git add AGENTS.md .agents .github skills docs
 git commit -m "chore: add VibeExe coding agent instructions"
```

The visible `skills/` directory mirrors `.agents/skills/`. Keep `.agents/skills/` as the canonical agent location. The visible copy is included for inspection and portability.
