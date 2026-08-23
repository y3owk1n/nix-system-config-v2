# Loop Approaches

Extended approaches for constructing a feedback loop, beyond the core four (failing test, curl script, CLI invocation, headless browser).

5. **Replay a captured trace.** Save a real request/payload/event log to disk; replay through the code path in isolation.
6. **Throwaway harness.** Minimal subset of the system (one service, mocked deps) exercising the bug path.
7. **Property / fuzz loop.** If the bug is "sometimes wrong output", run 1000 random inputs and look for the failure mode.
8. **Bisection harness.** If the bug appeared between two known states, automate "boot at state X, check, repeat" for `git bisect run`.
9. **Differential loop.** Same input through old-version vs new-version, diff outputs.
10. **Human in the loop.** Last resort — a script that prints one instruction, waits for the human to do it, and reads back the result. Use when the trigger needs a human hand (a physical device, a third-party UI, an SSO prompt).
