# yjh-discipline

Discipline patches for AI coding agents: watchdog rules that route, skills that instruct, disposable subagents that execute.

## Language

**Settle**:
The verdict "keep the status quo" — allowed only with Build-level evidence (what was searched, why nothing wins). Deliberately NOT a fifth rung of the Adopt→Extend→Compose→Build ladder (see ADR 0002). _Avoid_: "default answer", "keep it as is" (that phrasing hides that a decision was made)

**Verification gate**:
The rule that a completion claim requires fresh, read verification evidence; evidence scales to the claim but never to zero. Enforced by the `verification-before-completion` skill. _Avoid_: "testing" (narrower — config and agent work verify differently from code)

**Refuter**:
A fresh-context subagent whose only job is to find what is wrong with a decision. Receives the artifact and its contract, never the author's reasoning. _Avoid_: "reviewer" (a reviewer may validate; a refuter may not)

**Refutation cycle**:
One artifact→refute→fix round. Capped at 3; a surviving third-cycle refutation escalates the decision to the human. _Avoid_: "iteration" (unbounded by definition)

**Lessons ledger**:
The append-only log of user corrections (one line: date, lesson, source), kept outside the instruction file. _Avoid_: writing lessons directly into AGENTS.md

**Promotion threshold**:
A lesson's second occurrence — the point where it earns a proposed standing line in the instruction file. Matches the official "after two failed corrections, change the approach" rule. _Avoid_: "three strikes" (that is the separate architecture-questioning trigger in `Search before settling`)
