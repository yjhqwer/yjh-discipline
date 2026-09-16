# Core Engineering Directives

Strictly adhere to the following rules across all coding, system engineering, and configuration management tasks.

## 1. Think Before Acting

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before taking action:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Prior Art & Adversarial Decision

**Search before building. Challenge non-trivial decisions.**

### Prior art before building
- Run the `prior-art-search` skill before non-trivial features, skills, configs, or library choices. Exempt: bug fixes, refactors, config-value edits, or when a verdict already exists in Hindsight memory.
- Outcomes: **Adopt** (proven solution fits directly) / **Extend** (covers ~80%, adapt the remaining 20%) / **Compose** (combine 2-3 small pieces) / **Build** (nothing suitable - state what was checked).
- Skipping research at the user's request is itself a decision: note it in one line and proceed.
- When the current approach fails, breaks something else, or survives only on manual workarounds, treat it as a search trigger and find the better method first - "keep the status quo" is a decision to justify (including "do nothing" among the alternatives), not a default answer.

### Adversarial review
- Decisions that are hard to reverse - architecture, config design, irreversible blast radius, prior-art verdicts - get a fresh-context refuter before they stand: it sees the artifact and acceptance criteria only, never the author's reasoning; 3 refuted cycles go to the human.

## 3. j-space For Non-Trivial Work

Before starting any non-trivial task (multi-step work, planning, complex debugging, anything spanning many turns), load the `j-space` skill first and follow its pass system (fast/full/loop). Trivial requests need nothing.

## 4. Subagent Delegation & Context Guard

**Protect the main thread. Delegate deep exploration.**

### When to delegate
- Hand exploration to a disposable subagent when a task needs reading **more than ~3 files or enters unfamiliar territory**. Never perform long sequential multi-file reads in the main thread.
- Handle inline: single-file edits, ambiguous scope, destructive operations, and purely mechanical changes (e.g. renames spanning a few files).
- Spawn **multiple** subagents only for 2+ independent tasks with no shared state.
- When torn between two sizes, pick the smaller one.

### Task sizing
- **Small** (typos, lint, mechanical edits): solo, no fan-out, no external search.
- **Medium** (one component or script, picking an in-ecosystem utility): check the local repo and installed skills/memory first; search externally only if that comes up empty.
- **Large** (multi-file features, architecture, configurations such as `CLAUDE.md`/CI/Docker, rules, skills, security-sensitive modules): delegate exploration.

### Delegation briefs
Subagents know nothing: every subagent gets a self-contained brief - exact question, boundaries (read-only, allowed paths), relevant file paths and constraints - and must return a structured synthesis with file paths and line ranges, never raw dumps or whole files.

## 5. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" -> "Write tests for invalid inputs, then make them pass"
- "Fix the bug" -> "Write a test that reproduces it, then make it pass"
- "Refactor X" -> "Ensure tests pass before and after"
- "System / Service Changes" -> "Define live verification checks (socket/port via `ss -tulnp`, HTTP response, config syntax validation)"

For multi-step tasks, state a brief plan:
```
1. [Step] -> verify: [check]
2. [Step] -> verify: [check]
3. [Step] -> verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

- **Evidence before assertions:** Before claiming any work done, run the check that proves it and read the result. Evidence scales to the claim but never to zero; after proof passes, stop.
- **Log Context Discipline:** When diagnosing or checking logs, enforce output capping (e.g. `2>&1 | tail -c 4000`) to prevent massive log dumps from blowing up the context window.

## 6. Lessons Ledger

- When the user corrects you, append the lesson (date, one line, source) to `~/.agents/LESSONS.md`. First offense stays in the ledger; when the same lesson fires a second time, propose it as one standing line in this file - second offense is the promotion threshold.

## 7. Simplicity First

**Minimum code and minimal changes that solve the problem. Nothing speculative.**

- **For Code:**
  - No features beyond what was asked.
  - No abstractions for single-use code.
  - No "flexibility" or "configurability" that wasn't requested.
  - No error handling for impossible scenarios.
  - If you write 200 lines and it could be 50, rewrite it.
- **For Systems & Operations:**
  - Prefer native Linux CLI tools and lightweight operations; do not introduce heavy suites or unrequested background daemons.
  - Respect resource constraints (1G/2G RAM) and maintain memory awareness to prevent OOM kills.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 8. Surgical Changes

**Touch only what you must. Clean up only your own mess. Contain blast radius.**

- **When editing existing code:**
  - Don't "improve" adjacent code, comments, or formatting.
  - Don't refactor things that aren't broken.
  - Match existing style, even if you'd do it differently.
  - If you notice unrelated dead code, mention it - don't delete it.
  - Remove imports/variables/functions that YOUR changes made unused; don't remove pre-existing dead code unless asked.
- **When editing system configurations:**
  - Never leave stray `.bak` files inside drop-in configuration directories (`/etc/nginx/conf.d/`, `/etc/sudoers.d/`, `/etc/cron.d/`, `/etc/systemd/system/*.d/`).
  - Always run configuration tests (e.g. `nginx -t`) and prefer graceful reload over abrupt restart.

The test: Every changed line or configuration entry should trace directly to the user's request.
