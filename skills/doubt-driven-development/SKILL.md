---
name: doubt-driven-development
description: "Subjects every non-trivial decision to a fresh-context adversarial review before it stands. Use when a decision modifies branching logic, crosses a module or service boundary, asserts a property no compiler can check, depends on unseen context, has an irreversible blast radius, settles a prior-art verdict (Adopt/Extend/Compose/Build), or any time a confident output would be cheaper to verify now than to debug later."
---

# Doubt-Driven Development

A decision that was never attacked is not validated — it is untested. Before a non-trivial decision becomes the plan, a fresh-context reviewer whose only job is to prove it wrong gets one swing at it.

## When it fires

Any of:

- the change modifies branching logic
- it crosses a module or service boundary
- it asserts a property no compiler or type-checker can verify
- it depends on context the decision-maker cannot see
- its blast radius is irreversible (production auth, security-sensitive logic, data migration, public-facing actions)
- a prior-art verdict (Adopt / Extend / Compose / Build) is about to be recorded

## When it stays silent (exclusions)

Mechanical operations; changes the user explicitly prescribed; reading and summarizing; one-line obvious changes; pure tooling work; and any time the user has chosen speed over verification. When "non-trivial" is genuinely unclear, the cost asymmetry decides: a refutation run costs minutes, debugging a confident wrong decision costs hours.

## Procedure

1. **FRAME** — Write the decision as an **ARTIFACT** (the plan, design, or verdict itself) plus a **CONTRACT** (the acceptance criteria it must meet). The artifact never travels with the author's reasoning or self-defense.
2. **REFUTE** — Dispatch a fresh-context subagent with the artifact and contract only:

   > Adversarial review. Find what is wrong with this artifact. Assume the author is overconfident. Check it against the contract only. Do NOT validate. Do NOT summarize. Report every gap as: claim → why it fails → what evidence would change your mind.

3. **RESOLVE** — Fix the artifact for each surviving gap and re-run the refuter. Maximum **3 cycles**; if the third cycle still refutes, stop and take the decision to the human with both sides summarized.

The refuter never sees the author's justification — only what was decided and the bar it must clear. Fresh context is the point: no shared enthusiasm, no sunk-cost politeness.

---

*Extended from addyosmani/agent-skills `doubt-driven-development` (MIT); trigger list extended with prior-art verdicts.*
