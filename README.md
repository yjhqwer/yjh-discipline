# yjh-discipline

**Stop your coding agent from grinding blind, drowning your own context, and ignoring the skills you installed.**

Three discipline patches for AI coding agents (Claude Code, Codex, Cursor, Gemini CLI, Antigravity, OpenCode, …). They look independent. They are not — each one fails without the other two.

> The best code and configurations are the ones already battle-tested by the global community.

---

## The three failure modes

You have seen all three. Most agents have all three at once.

### 1. It won't delegate — your context drowns

The agent does everything in the main thread: 40 grep and read calls, full-file dumps, search results pasted inline. By the time it finds the answer, the window is stuffed with noise, every later token re-pays for that noise, and the plan from 30 minutes ago has fallen out of attention.

| Before (main thread grinds) | After (delegated) |
|---|---|
| Dozens of `grep`/`read`/fetch calls flood the conversation | A disposable subagent reads everything in its own clean window |
| 872 KB file read raw: **1.58M tokens, 45 tool calls** in one research pass (measured in the author's own session) | Same task with a structured brief: **~110K tokens**, verdict back in one screen |
| Agent forgets the goal mid-task | Main thread keeps only the conclusion, not the evidence |

### 2. It grinds instead of searching — closed-door engineering

Given a new feature, config, or integration, the agent invents from imagination: hand-rolled solutions to solved problems, broken configurations, reinvented standards. Writing code is fun; checking whether someone already solved it is boring — so agents skip the boring part.

| Before (grind first) | After (search first) |
|---|---|
| Writes a custom solution for a problem with a 20K-star library | Finds the battle-tested implementation first |
| No evidence anything better exists | Every decision ends in a verdict: **Adopt / Extend / Compose / Build** |
| Bugs from misusing APIs it guessed at | Known pitfalls documented before the first line is written |

### 3. It ignores the skills you installed

Skills are lazy-loaded. An installed skill does **nothing** until the agent decides to look for it — and agents default to not looking. The author watched an installed methodology skill get zero automatic triggers for **months**. A skill that never fires is dead weight with a nice folder name.

| Before (install and pray) | After (routed) |
|---|---|
| Skill sits in `~/.agents/skills/`, never mentioned by the agent | One standing rule in the instruction file forces a skill check before non-trivial work |
| "I didn't know there was a skill for that" | The skill list is consulted every session, triggers fire reliably |

---

## Why they must be solved together (The Trinity)

Each patch closes the loophole the other two open:

- Solve **#2** alone ("go search!") and the agent searches **in the main thread** — you traded grinding for context bloat (#1).
- Solve **#1** alone (delegation) with no search discipline, and you get perfectly isolated agents **reinventing wheels in parallel** (#2).
- Solve both with skills but no routing, and **nothing ever triggers** (#3).

```
┌─────────────────────────────────────────────────────────────┐
│  1. THE WATCHDOG (rules in AGENTS.md / CLAUDE.md)           │
│     Forces routing: search before building; delegate        │
│     bulk reading; check the skill list before working.      │
└──────────────────────────────┬──────────────────────────────┘
                               │ forces trigger
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  2. THE TOOLBOX (Agent Skills)                              │
│     prior-art-search: the research SOP + the                │
│     Adopt → Extend → Compose → Build verdict ladder.        │
│     delegate-or-die: the delegation + brief format.         │
└──────────────────────────────┬──────────────────────────────┘
                               │ delegates execution
                               ▼
┌─────────────────────────────────────────────────────────────┐
│  3. THE DISPOSABLE SUBAGENT                                 │
│     Runs every search and file read in an isolated          │
│     context. Returns only the verdict (<250 words),         │
│     never the evidence.                                     │
└─────────────────────────────────────────────────────────────┘
```

Which layer fixes which failure mode — and why the split is not negotiable:

| Failure mode | Rules layer (always in context) | Skill layer (loaded on demand) |
|---|---|---|
| ① Won't delegate | The trigger: ">3 files → subagent; briefs self-contained" | `delegate-or-die`: full brief anatomy & output contract |
| ② Grinds blind | The trigger: "search first; Adopt → Extend → Compose → Build" | `prior-art-search`: search order & verdict report |
| ③ Ignores skills | The routing rule — **rules only** | — none possible: a skill can't cure its own non-triggering |

**Rules decide *when*, skills decide *how*, subagents do the *work*.**

---

## What's inside

```
yjh-discipline/
├── rules-template.md              # The watchdog: paste into AGENTS.md / CLAUDE.md / GEMINI.md
└── skills/
    ├── prior-art-search/SKILL.md  # Search-before-building SOP + verdict ladder
    ├── delegate-or-die/SKILL.md   # When to delegate + the self-contained brief format
    └── j-space/                   # A thinking workspace for non-trivial work (upstream SV1: 13 modules, 7 references, controller scripts)
```

**j-space** is a verbatim copy of the [**J-Space Cognition Suite**](https://github.com/Tiger3807861189/J-Space-Cognition-Suite) by Tiger3807861189 (3000+ stars), tracking the current upstream release (SV1, September 2026; Apache-2.0 — its `LICENSE` and `THIRD_PARTY_NOTICES.md` ship inside the skill folder). The suite turns Anthropic's J-space research (Gurnee et al., July 2026) into a working method: grade a task's intensity, route it into one of three passes (fast / full / loop), keep durable state across long work, and think in a workspace instead of on the page. A fourth trigger line in the rules template routes to it: non-trivial work loads the skill first.

## Install

**Any agent supporting the [Agent Skills standard](https://agentskills.io)** (Claude Code, Codex, Cursor, Gemini CLI, OpenCode, Antigravity, and 60+ more):

```bash
npx skills add yjhqwer/yjh-discipline
```

**Manual**: copy any `skills/<name>/` folder into your agent's skills directory (`~/.claude/skills/`, `~/.agents/skills/`, …).

**Or just ask your agent**: paste this to any agent with file access — *"Install the skills from github.com/yjhqwer/yjh-discipline into my agent's skills directory."*

**After installing**: restart your agent — skills are scanned at startup, so a running session keeps seeing the old list. To self-check the bundled j-space suite, run `python skills/j-space/scripts/verify_suite.py`; its own README and Apache-2.0 license live inside the folder.

**The watchdog rules** are not a skill — they must live in your agent's instruction file, where they are seen every session. Copy `rules-template.md` (or just the sections you need) into `AGENTS.md` / `CLAUDE.md` / `GEMINI.md`. Without them, the skills rarely fire on their own — that is failure mode #3.

## Design principles

- **Only what models can't infer.** Rules describe failure modes and defaults, not toy trigger lists.
- **Procedures in skills, standing bans in rules, one-offs in chat.** Each layer has one job.
- **Quality over budget.** Subagent briefs define the output contract, never token caps — budgets make agents timid; contracts make them precise.
- **Status-first reporting.** Every delegated task returns `STATUS: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT` before any content, so a failed delegation costs one line, not a wall of text.

## Tested, not just written

The three skills plus the routing rules were trigger-tested in isolated agent sessions (GLM-5.3-Flash — a flash-tier model), with every tool call verified from session logs. (The `j-space` row was measured on the previously bundled earlier copy, since replaced with the verbatim upstream SV1.):

| Test prompt | Expected | Result |
|---|---|---|
| "Explain the login module, read all the related files" | Delegate; main thread stays clean | ✅ 1 subagent did all 6 file reads; the main thread only spot-checked and relayed the synthesis |
| "Add automatic retry for failed requests" | Search prior art before writing code | ✅ `prior-art-search` loaded; a research subagent ran 7 web fetches (main thread: 0); ended in an evidence-backed `Verdict: Build` before any code |
| "Rename variable `usr` to `user`" | Nothing should fire | ✅ Tool trace is just Read → Edit. No skills, no subagents, no web calls |
| "Plan a refactor of src/auth: extract session logic, outline only" | Load `j-space` before planning | ✅ First tool call was `Skill: j-space`; it then loaded `delegate-or-die` and sent one read-only subagent to do the file exploration — `prior-art-search` correctly stayed silent (refactors are exempt) |

Positive and negative cases both pass: the skills fire when they should and stay quiet when they shouldn't.

## Credits & lineage

This repo is an *Extend*, not a *Build* — it composes ideas the community already proved:

- [anthropics/skills](https://github.com/anthropics/skills) — the Agent Skills format and ecosystem
- [obra/superpowers](https://github.com/obra/superpowers) — proof that skills-based discipline works at scale (and the case for staying lightweight: this repo is ~2% the size)
- [shimo4228/search-first](https://github.com/shimo4228/search-first) & [anombyte93/claude-research-skill](https://github.com/anombyte93/claude-research-skill) — search-before-building SOPs
- [techygarg's subagent-cost-economy](https://gist.github.com/techygarg/f8f98a2f026538fad4a69b593a964d95) — the "protect the main thread, delegate the research" cost argument
- [jbarbier/CLAUDE.md](https://github.com/jbarbier/CLAUDE.md) — the rules-file-as-working-contract framing
- [SuperClaude-Org/SuperClaude_Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework) — the failure-investigation framing: errors and leftover workarounds as explicit research triggers ("fix, don't workaround")
- [decision-records/decision-records](https://github.com/decision-records/decision-records) — the "including 'do nothing'" considered-options pattern: the status quo is a decision, not a default
- Minimal rules collections in the Karpathy spirit: [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills), [vinta/hal-9000](https://github.com/vinta/hal-9000)
- [Tiger3807861189's J-Space Cognition Suite](https://github.com/Tiger3807861189/J-Space-Cognition-Suite) — the bundled `j-space` skill is a verbatim copy of this suite (tracking upstream SV1), redistributed under its Apache-2.0 license (license and notices included in the skill folder)
- Anthropic's interpretability research, [*"Verbalizable Representations Form a Global Workspace in Language Models"*](https://transformer-circuits.pub/2026/workspace/index.html) (Gurnee, Sofroniew, Lindsey et al., July 2026) — the discovery of **J-space**; the bundled j-space suite is built on this finding

Except for the `j-space` suite, which is redistributed verbatim under its own license, no text from these projects is included — what's borrowed is the ideas, and by this repo's own rules, ideas get credited.

The Trinity framing — rules route, skills instruct, subagents execute, and all three are required — is the delta.

## License

MIT. If it saved your context window once, ⭐ the repo.
