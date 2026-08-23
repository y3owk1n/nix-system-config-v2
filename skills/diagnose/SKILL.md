---
name: diagnose
description: "Diagnosis loop for hard bugs and performance regressions."
---

# Diagnose

A discipline for hard bugs. Skip phases only when explicitly justified.

## Redact

Redact every secret: write `<REDACTED>` in its place. Build loops against env vars so credentials stay in the environment. Captured artifacts carry auth headers — quote only the lines with signal.

## Phase 1: Build a feedback loop

This is the skill. Everything else is mechanical. If you have a **tight** pass/fail signal for the bug (one that goes red on _this_ bug), you will find the cause. If you don't have one, no amount of staring at code will save you.

Spend disproportionate effort here. Be aggressive. Be creative. Refuse to give up.

### Ways to construct one (roughly in order)

1. **Failing test** at whatever seam reaches the bug.
2. **Curl / HTTP script** against a running dev server.
3. **CLI invocation** with a fixture input, diffing stdout against a known-good snapshot.
4. **Headless browser script** (Playwright / Puppeteer) driving the UI and asserting on DOM/console/network.

For more approaches (replay traces, throwaway harnesses, property/fuzz loops, bisection, differential loops, HITL scripts), see `LOOP-APPROACHES.md`.

### Tighten the loop

Treat the loop as a product. Once you have _a_ loop, tighten it:

- Faster? Cache setup, skip unrelated init, narrow test scope.
- Sharper signal? Assert on the specific symptom, not "didn't crash".
- More deterministic? Pin time, seed RNG, isolate filesystem, freeze network.

A 30-second flaky loop is barely better than no loop; a 2-second deterministic one is a debugging superpower.

### Non-deterministic bugs

The goal is a **higher reproduction rate**. Loop the trigger 100x, parallelise, add stress, narrow timing windows. A 50%-flake bug is debuggable; 1% is not.

### When you genuinely cannot build a loop

Stop and say so. List what you tried. Ask the user for: (a) access to the reproducing environment, (b) a redacted captured artifact, or (c) permission to add temporary instrumentation. Do not proceed to hypothesise without a loop.

### Phase 1 gate

A tight loop that goes red. Done when you can name **one command** you have **already run at least once** that is:

- [ ] **Red-capable**: drives the actual bug code path and asserts the user's exact symptom.
- [ ] **Deterministic**: same verdict every run (or pinned high reproduction rate).
- [ ] **Fast**: seconds, not minutes.
- [ ] **Agent-runnable**: you can run it unattended.

No red-capable command, no Phase 2.

## Phase 2: Reproduce + minimise

Run the loop. Watch it go red.

Confirm:

- [ ] The loop produces the failure mode the **user** described, not a different failure.
- [ ] Reproducible across multiple runs (or high enough rate to debug against).
- [ ] Exact symptom captured (error message, wrong output, slow timing).

### Minimise

Shrink the repro to the **smallest scenario that still goes red**. Cut inputs, callers, config, data, steps **one at a time**, re-running after each cut. Keep only what's load-bearing.

Done when **every remaining element is load-bearing**: removing any one makes the loop go green.

Do not proceed until you have reproduced **and** minimised.

## Phase 3: Hypothesise

Generate **3-5 ranked hypotheses** before testing any. Single-hypothesis generation anchors on the first plausible idea.

Each hypothesis must be **falsifiable** — state the prediction:

> "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse."

If you cannot state the prediction, the hypothesis is a vibe: discard or sharpen it.

Show the ranked list to the user before testing. They often have domain knowledge that re-ranks instantly. Don't block on it; proceed with your ranking if the user is AFK.

## Phase 4: Instrument

Each probe must map to a specific prediction from Phase 3. Change one variable at a time.

Tool preference:

1. **Debugger / REPL inspection** if available. One breakpoint beats ten logs.
2. **Targeted logs** at the boundaries that distinguish hypotheses. Tag every debug log with a unique prefix, e.g. `[DEBUG-a4f2]`. Cleanup becomes a single grep.

**Perf branch:** For performance regressions, establish a baseline measurement first, then bisect. Measure first, fix second.

## Phase 5: Fix + regression test

Write the regression test **before the fix**, but only if there is a **correct seam** for it.

A correct seam exercises the **real bug pattern** as it occurs at the call site. If the only available seam is too shallow, a regression test there gives false confidence.

**If no correct seam exists, that itself is the finding.** Note it. Flag this for the next phase.

If a correct seam exists:

1. Turn the minimised repro into a failing test at that seam.
2. Run it. Confirm it fails.
3. Apply the fix.
4. Run it. Confirm it passes.
5. Re-run the Phase 1 feedback loop against the original scenario.

## Phase 6: Cleanup

Delete the throwaway harnesses and prototypes. State the confirmed hypothesis in the commit or PR body — the next person to hit this reads that line, not the diff.

## Completion

Done when: the Phase 1 loop runs green against the original scenario, the regression test passes (or the absence of a correct seam is written down as a finding), every `[DEBUG-...]` tag is gone, and the confirmed hypothesis is in the commit or PR body. Checkable: re-run the Phase 1 command and `grep -r "DEBUG-" .` returns nothing.
