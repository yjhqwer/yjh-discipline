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

### Search before settling

- Errors, unexpected breakage, and "only a manual workaround remains" are investigation triggers, not stopping points: find the root cause and the better method before recommending changes to the user's setup. Symptom-level fixes are failure.
- If three attempts fail, question the approach itself instead of sticking with it through sheer inertia — and never present a workaround as the answer when the real fix exists.
- "Keep the status quo" is a decision, not a default: list it among the realistic alternatives — including "do nothing" — and justify it with the same evidence as any other verdict.
- *Full procedure (search order, verdict report): the `prior-art-search` skill.*

### Verify before you claim it

- Before claiming work complete, fixed, or passing, run the check that proves it and read the result — evidence before assertions, on every claim. Evidence scales to the claim but never to zero.
- After proof passes, stop: report commands, results, and unresolved risk. Verification ends a task; it does not open a new one.
- *Full procedure (the claim/proof table, five-step gate): the `verification-before-completion` skill.*

### Doubt before it stands

- Decisions that are hard to reverse — architecture, config design, irreversible blast radius, and prior-art verdicts (Adopt/Extend/Compose/Build) — get a fresh-context refuter before they stand. The refuter receives the artifact and its acceptance criteria, never the author's reasoning; its only job is finding what is wrong. Three refuted cycles go to the human.
- *Full procedure (triggers, exclusions, refuter brief): the `doubt-driven-development` skill.*

### Keep a lessons ledger

- When the user corrects you, append the lesson to a dedicated ledger file: date, the lesson in one line, the source. Do not touch the instruction file for a first offense.
- When the same lesson fires a second time, propose it as one standing line in the instruction file — second offense is the promotion threshold, matching the official "after two failed corrections, change the approach" rule.

### Use the skills you installed

- Skills are lazy-loaded: an installed skill does nothing until you check for it. Before starting non-trivial work, check the available skill list and load any that matches the task.
- Standing rules belong in this file, procedures belong in skills, one-off instructions belong in the conversation. Keep each layer to its own job.

### Think in a workspace, not on the page

- Multi-step work, planning, complex debugging, anything that will span many turns: load the `j-space` skill first and classify the task into one of its passes before answering. Trivial requests need nothing.
- *Full method (the workspace premise, the three passes, the ledger): the `j-space` skill.*

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
