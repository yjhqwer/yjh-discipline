---
name: delegate-or-die
description: "Delegation discipline for coding agents. Hand multi-file exploration, broad searches, and long sequential reads to disposable subagents instead of flooding the main thread with tool calls. Includes the self-contained brief format (question, boundaries, output contract) and status-first reporting. Use whenever a task would require reading more than ~3 files, running multi-query research, or touching unfamiliar territory."
---

# Delegate or Die (Protect the Main Thread)

**The main conversation is for decisions, not for bulk reading.**

Every grep result, file dump, and fetched page that lands in the main context is re-paid on every later turn, crowds out the original goal, and accelerates context rot. The agent that keeps its main thread clean is the agent that still knows what it's doing an hour in.

---

## 1. When to delegate

Delegate when any of these is true:

- The answer requires reading **more than ~3 files**, or enters unfamiliar territory.
- The task is a **search sweep**: multiple queries, page fetches, or comparing options.
- There are **2+ independent tasks with no shared state** — spawn parallel subagents.

Handle inline only:

- Single-file edits
- Ambiguous scope where you need the user in the loop
- Destructive operations
- Purely mechanical changes (renames spanning a few files)

When torn between two sizes, pick the smaller delegation.

## 2. The brief

Subagents know nothing. They inherit no conversation, no project memory, no intent. Every brief must be self-contained:

1. **The exact question** — one sentence, not a topic.
2. **Boundaries** — read-only or allowed to write; which paths are in scope.
3. **Relevant file paths and constraints** — anything they'd waste calls discovering.
4. **The output contract** — what the final message must contain and must not contain.

**Quality over budget.** Do not cap tokens or tool calls — caps make agents timid and produce truncated work. Define the output contract instead; contracts make agents precise. The goal is one-pass completion, not cheapest completion.

## 3. The output contract

Every delegated task returns:

- **Status line first**, before any content:
  - `STATUS: DONE`
  - `STATUS: DONE_WITH_CONCERNS` — name the doubts
  - `STATUS: BLOCKED` — name the blocker
  - `STATUS: NEEDS_CONTEXT` — name what is missing
- A **structured synthesis** with file paths and line ranges, so claims are checkable.
- **Never** raw dumps, whole-file pastes, or transcripts of the search process.

A `BLOCKED` or `NEEDS_CONTEXT` subagent returns early with just the status and a one-line reason — it must not pad the report to fill the format.

## 4. After the return

- **Don't repeat the delegated work in the main thread.** Once dispatched, wait for the result — re-running the search yourself doubles the cost and re-floods the context you just protected.
- **Verify before acting.** Check cited paths and line ranges before building on a subagent's claims; a synthesis is cheaper to verify than to redo.
- **Relay what matters.** The subagent's report is not shown to the user — surface the conclusion in your own words.
