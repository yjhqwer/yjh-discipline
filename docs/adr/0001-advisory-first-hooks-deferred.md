---
status: accepted
---

# Advisory first: the hook hard-gate is deferred

Anthropic's official guidance layers enforcement: rules and skills are advisory, hooks are deterministic, and the full official shape of a verification gate includes a hook that blocks turn-end until the check passes. We ship only the advisory layer (skill + routing rule) because hook support is harness-specific — some target harnesses can remind but cannot block — and this pack targets 60+ agents. Harnesses that can enforce deterministically (e.g. Claude Code, ZCode) may add the hook layer locally; the skill and rule remain the portable baseline.

## Considered Options

- **Skill + rule only (chosen)** — portable everywhere; enforcement is advisory.
- **Hook gate included by default** — deterministic, but silently no-ops on harnesses that cannot block, and splits the pack into "works here, reminds there".
