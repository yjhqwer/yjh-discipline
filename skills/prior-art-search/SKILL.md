---
name: prior-art-search
description: "Mandatory pre-implementation research skill. Search GitHub, official documentation, package registries, and existing battle-tested implementations before writing new features, rules files, skills, or architecture. Enforces the Adopt-Extend-Compose-Build hierarchy and delegates heavy search loops to subagents to prevent main-thread context bloat. Use before any non-trivial feature, skill, config, or library choice — and whenever an existing approach fails or survives only on a workaround and 'keep the status quo' is tempting — not for bug fixes, refactors, or mechanical changes."
---

# Prior Art Search (Search Before Building)

**The best code and configurations are the ones already battle-tested by the global community.**

Before designing architecture, writing non-trivial features, creating skills, or synthesizing configurations (rules files, CI/CD, Docker), search for existing solutions first. Do not invent from imagination.

**Settling counts as building.** When the current approach fails, breaks something else, or survives only through manual workarounds, search for a better method before recommending the user keep the status quo. "Keep the status quo" is a verdict like any other: it needs evidence that no better method exists — not just that the workaround was easy.

---

## 1. The Decision Hierarchy: Adopt → Extend → Compose → Build

Assess all candidates through this strict precedence ladder:

1. **Adopt (Direct Reuse)**
   - If an official template, high-starred repository, or standard library solves the problem, use it directly.
   - Do not re-implement existing standards.
2. **Extend (Adapt & Specialize)**
   - If a proven solution covers ~80% of the requirements, adapt only the remaining 20% for local constraints.
   - Credit the reference pattern and document the adaptation delta.
3. **Compose (Combine Small Pieces)**
   - If 2–3 small, maintained packages together cover the requirements better than one heavy dependency, combine them.
4. **Build (Novel Implementation)**
   - Only implement original logic from scratch when research proves no satisfactory prior art exists, or the problem is genuinely novel.

---

## 2. Search Priority Ladder

Execute queries in this order, stopping early when a definitive solution is found:

**Before any tool call**: state in plain text what functionality is needed, in which language/framework, and the constraints — so the direction can be corrected early.

**Do not run this skill for**: bug fixes, refactoring, config-value edits, or purely mechanical changes. If the user says research is unnecessary, skipping is itself a decision — record a one-line verdict noting it was skipped at the user's request.

**Query craft**: search in the language of the index you are querying — for international technical content that usually means English keywords, whatever the working language is. Never translate proper nouns, product names, or technical terms: query `cloudflare` as `cloudflare`, not as its translation.

0. **Persistent memory & past decisions**
   - Query your long-term memory tool or check `docs/decisions/` (ADRs) first.
   - If a proven approach or verdict was previously recorded, reuse it immediately — sub-second retrieval, zero network calls.
1. **Local & installed**
   - Grep the current repository for existing helper functions, patterns, or utilities.
   - Check installed skills and active MCP servers.
2. **Package registries & official standards**
   - Check the official ecosystem registries (npm, PyPI, crates.io, Go modules) and official vendor documentation.
3. **Open-source prior art (GitHub / Web)**
   - Search for popular, maintained implementations, star-tested patterns, and official recipes.
   - Search for known pitfalls, edge cases, and post-mortems for this specific domain.

---

## 3. Subagent Execution & Context Isolation

**Never pollute the main thread with raw search queries, page dumps, or scraping results.**

**Quick vs Full**: an obvious single lookup runs inline (Quick); anything broader delegates the sweep to a subagent (Full).

- **Delegate the sweep**: spawn a disposable research subagent with the specific inquiry:
  - *"Investigate existing open-source solutions, GitHub repositories, and best practices for [TASK/DOMAIN]. Identify the top 2 battle-tested approaches."*
- **Disposable context**: the subagent executes all multi-query searches and page fetches in its own isolated context.
- **Punch-list return**: the subagent synthesizes findings and returns **only** the structured verdict below to the main conversation.
- **Status-first return**: the report MUST open with one status line before any content: `STATUS: DONE` | `STATUS: DONE_WITH_CONCERNS` (name the doubts) | `STATUS: BLOCKED` (name the blocker) | `STATUS: NEEDS_CONTEXT` (name what is missing). A `BLOCKED` / `NEEDS_CONTEXT` subagent returns early with just the status and a one-line reason — it must not pad the report to fill the format.

---

## 4. Required Output: The Verdict Report

Every prior-art investigation must conclude with this concise structured format (<250 words):

```markdown
### Prior Art Verdict

- **Status**: [DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT] — first line of the report; if not DONE, follow with doubts/blocker/missing info only
- **Verdict**: [Adopt | Extend | Compose | Build]
- **Selected Reference**: [Repository / Package / Template Name] (URL or package identifier)
- **Quality Signal**: [Stars / Maintenance status / Official endorsement]
- **Adoption Strategy**:
  - If **Adopt**: direct usage instructions / dependencies to install.
  - If **Extend**: what 80% is reused, and what exact 20% must be written locally.
  - If **Build**: explicit proof of why existing solutions are unsuitable.
- **Known Pitfalls**: [Key gotchas or anti-patterns discovered during research]
```

One-line variant for small passes: `Verdict: <Adopt|Extend|Compose|Build> — <target or "custom"> — <evidence-based reason>`. A pass that searches but records no verdict line is incomplete.

---

## 5. Memory Write-Back (The Flywheel)

Whenever a **strategic** verdict is confirmed and adopted:

- Persist the core decision to your long-term memory tool, or record a local ADR in `docs/decisions/`.
- This ensures future sessions in this codebase build on past discoveries rather than repeating identical external searches.
