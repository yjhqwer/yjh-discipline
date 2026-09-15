---
name: verification-before-completion
description: "Use when about to claim work is complete, fixed, or passing, before committing or reporting back - requires running a verification command and reading its output before making any success claims; evidence before assertions always."
---

# Verification Before Completion

**Iron Law: NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.**

An unverified "done" is a guess wearing a confident tone. The proof is the check — run fresh and actually read — not the memory of having written the change.

## The claim/proof table

| Claim | Requires | Not Sufficient |
|---|---|---|
| Tests pass | Test command run fresh, full output read, failures = 0 | "I wrote the tests" / an earlier green run |
| Build works | Build command exits 0 | "It looks right" |
| Bug fixed | The original failure scenario re-run, now showing the fix | Code inspection alone |
| Config/service works | The service probed after reload (health check, status endpoint, API call) | File edited + restart claimed |
| Subagent completed | Its report read AND its evidence independently spot-checked | Report says DONE |
| Requirements met | Each requirement mapped to its evidence | A summary paragraph |

**Evidence scales to the claim.** A one-line typo needs the changed line read back; a feature needs its test, build, or screenshot. What never scales to zero is *some* fresh, read output.

## The gate

1. **IDENTIFY** — What command or probe would prove this claim?
2. **RUN** — Execute it fresh and complete, not "I ran it earlier".
3. **READ** — Full output, exit code, failure count. Not the first line — the verdict.
4. **VERIFY** — Does the output confirm the claim as stated?
5. **ONLY THEN** — Make the claim, citing the evidence.

## After proof passes, stop

Report commands, results, and unresolved risk — then stop. No polish, no cleanup, no unrelated tests after the criteria pass. Verification ends a task; it does not open a new one.

---

*Extended from obra/superpowers `verification-before-completion` and juliusbrussee/caveman `verify-and-stop` (both MIT); wording adapted.*
