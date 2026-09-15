# tests/ — the trigger exam

Rules rot silently: you change a wording, a trigger dies, and nothing tells you. This directory is the exam that tells you.

Method: every case runs in a **fresh, isolated agent session** against a sandbox workspace, and the verdict is read from the **session log's real tool calls** — never from the agent's self-report. The sandbox gets the pack's skills and `rules-template.md` as its instruction file, so the exam always measures the current wording.

## Cases

See [cases.md](cases.md) — eight cases: four regression (the original trigger test) plus one per newer rule (settling, verification gate, doubt review, lessons ledger).

## Running

### ZCode (automated)

`run-zcode.ps1` runs each case headless through an isolated ZCode kernel (isolated HOME, minimal model config, sandbox workspace per case) and asserts on the rollout logs (main-thread vs `_subagent_` transcripts). **ZCode-only** — the kernel path and log format are host-specific; other harnesses can clone the approach but not the script.

Requirements: `node` on PATH, the ZCode desktop kernel, an OpenAI-compatible test model. Configure via env before running:

```
ZCODE_KERNEL      # path to zcode.cjs (default baked in for the maintainer's machine)
ZCODE_TEST_BASEURL, ZCODE_TEST_APIKEY, ZCODE_TEST_MODEL (default glm-5.3-flash)
```

Web-dependent cases (case 5) need the usual egress; if your machine needs a proxy for that, export `HTTPS_PROXY` before running.

### Any other agent (manual)

For each case in cases.md: open a fresh session in an empty sandbox project that has the pack's skills and the rules template as its instruction file, paste the case prompt, then judge the expected behavior against the tool trace your harness shows. Pass criteria are written per case.

## When to run

After **any** change to `rules-template.md` or a skill's trigger description. A rules change without a green exam is an unverified claim — which is exactly what the verification gate forbids.
