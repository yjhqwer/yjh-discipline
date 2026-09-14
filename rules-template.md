# Agent Discipline Rules — Template

Copy into your agent's instruction file (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, …).

Two parts, two jobs:

- **Part 1 — Core routing.** The always-visible trigger lines that decide *when* to delegate, *when* to search, and *when* to load a skill. Keep these even if you drop everything else — without them the skills in this repo rarely fire on their own.
- **Part 2 — General behavior.** Standalone behavioral defaults. Keep what resonates; each section is independent.

---

## Part 1 — Core routing

### Protect the main thread

- The main conversation is for decisions, not bulk reading. Hand exploration that needs reading more than ~3 files, or that enters unfamiliar territory, to a disposable subagent — keep its conclusion, not its evidence.
- A subagent brief must be self-contained: the exact question, the boundaries, the relevant paths, and the required output shape. Require a structured synthesis — never raw dumps or whole files.
- Once delegated, don't repeat the work yourself — wait for the report.
- *Full procedure (brief anatomy, output contract, status-first reporting): the `delegate-or-die` skill.*

### Search before building

- For non-trivial features, skills, configurations, or library choices, search for battle-tested prior art before writing anything. Judge candidates on the ladder **Adopt → Extend → Compose → Build**, and record the verdict in one line.
- Bug fixes, refactors, and config-value edits don't need research. If the user says to skip research, skipping is itself a decision — note it in one line and proceed.
- *Full procedure (search order, subagent sweeps, verdict report): the `prior-art-search` skill.*

### Use the skills you installed

- Skills are lazy-loaded: an installed skill does nothing until you check for it. Before starting non-trivial work, check the available skill list and load any that matches the task.
- Standing rules belong in this file, procedures belong in skills, one-off instructions belong in the conversation. Keep each layer to its own job.

## Part 2 — General behavior (optional, standalone)

### Think before coding

- State your assumptions explicitly. If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Surface tradeoffs before implementing. Push back when warranted.

### Simplicity first

- Minimum code that solves the problem. Nothing speculative.
- No features beyond what was asked. No abstractions for single-use code. No configurability that wasn't requested. No error handling for impossible scenarios.

### Surgical changes

- Touch only what the task requires. Match existing style, even if you'd do it differently. Don't refactor what isn't broken.
- Clean up only what your own change made unused. If you notice unrelated dead code, mention it — don't delete it.

### Goal-driven execution

- Transform tasks into verifiable goals: "add validation" becomes "write tests for invalid inputs, then make them pass".
- For multi-step work, state a brief plan first, with a verification check for each step.
