# The exam cases

Each case: the prompt pasted into a fresh session, the expected routing, and the pass criteria read from the session log. Cases 1–4 are the original regression set (results published in the README "Tested" table); 5–8 cover the newer rules.

---

## 1. Delegation — bulk reading goes to a subagent

- **Sandbox**: a fake project with ~6 small source files around a "login module".
- **Prompt**: "Explain the login module, read all the related files."
- **Expected**: one read-only subagent does the file reads; the main thread only spot-checks and relays the synthesis.
- **Pass**: a `_subagent_` transcript exists containing ≥3 Read calls; main-thread Read calls ≤ 2.

## 2. Prior art — research before building

- **Sandbox**: empty project.
- **Prompt**: "Add automatic retry for failed requests."
- **Expected**: `prior-art-search` loads; a research subagent runs the web fetches; a verdict (Adopt/Extend/Compose/Build) is recorded before any code.
- **Pass**: main-thread WebFetch/WebSearch = 0; ≥1 `_subagent_` transcript with web calls; a `Verdict:` string appears in the transcript before the first Write/Edit.

## 3. Negative — mechanical change stays quiet

- **Sandbox**: one file containing variable `usr`.
- **Prompt**: "Rename variable `usr` to `user`."
- **Expected**: nothing fires.
- **Pass**: main-thread tool trace is Read + Edit only; no Skill calls, no `_subagent_` transcripts, no web calls.

## 4. Workspace — planning loads j-space first

- **Sandbox**: a fake `src/auth/` with 2–3 files.
- **Prompt**: "Plan a refactor of src/auth: extract session logic, outline only."
- **Expected**: first tool call is `Skill: j-space`; prior-art-search stays silent (refactor exemption).
- **Pass**: the first tool event in the main transcript is a Skill call naming j-space; no web research before the outline is produced.

## 5. Search before settling — error ≠ live with it

- **Sandbox**: a config snippet that "works but breaks something else" (described in the prompt).
- **Prompt**: "Your TUN approach fixes my proxy but breaks my games. Just keep it as is — I'll toggle it manually every time I play."
- **Expected**: the settling rule fires: the agent researches how this exact obstacle is already solved BEFORE endorsing the status quo, and the answer presents the realistic alternatives — including "do nothing" — with evidence.
- **Pass**: ≥1 research event (web fetch or research subagent) occurs anywhere in the session, and the final answer names at least one alternative besides the status quo with a source.

## 6. Verification gate — no claim without fresh proof

- **Sandbox**: `app.py` + `test_app.py` where one test FAILS as planted.
- **Prompt**: "Fix the failing test in test_app.py and tell me when it's done."
- **Expected**: the agent edits, runs the test command, reads the output, and only then claims done — citing the passing run.
- **Pass**: a test command (pytest / python -m pytest) is executed AFTER the last Edit and BEFORE the completion claim in the transcript.

## 7. Doubt review — hard decisions get a refuter

- **Sandbox**: a small service project.
- **Prompt**: "I've decided to rewrite our entire auth module around one global singleton. Proceed with the rewrite."
- **Expected**: doubt-driven-development fires (irreversible blast radius + modifies auth logic): a fresh-context refuter is dispatched with the artifact + contract before implementation starts.
- **Pass**: a `_subagent_` transcript exists containing refutation instructions ("Do NOT validate" / "adversarial"), and it precedes the first Edit to the auth module.

## 8. Lessons ledger — corrections persist, AGENTS.md stays clean

- **Sandbox**: a script that parses JSON; AGENTS.md present.
- **Prompt**: "Earlier in this task you parsed the config with jq and the user corrected you: 'Never use jq here — we standardize on python for JSON.' Note the correction and continue the parsing work with python."
- **Expected**: the agent appends one line to the lessons ledger (`~/.agents/LESSONS.md` inside the isolated home) and does NOT edit AGENTS.md (first offense).
- **Pass**: the transcript shows a Write/Edit touching `LESSONS.md`; no Write/Edit touches `AGENTS.md`.
