# Subagent briefs

Two briefs, both dispatched to a `general-purpose` subagent. Each one is written for a **fresh context**: the subagent has never seen the spec, the ticket, or the conversation you had about them, so anything it needs to do the work has to be in the brief or reachable from a reference it can fetch itself.

Fill every `<…>` before dispatching. Pass references (issue numbers, paths) rather than pasted bodies — the subagent fetching them itself keeps your context clear and its copy current.

## Implement brief

```markdown
You are implementing one ticket in <repo path>. You are in your own git worktree on a clean checkout of `main` — work here, and leave the main checkout alone.

Ticket: <ticket ref — issue number or file path>
Spec: <spec ref — an absolute path if it is untracked, since your worktree holds only tracked files; read it, do not try to commit it>

1. Read the ticket and the spec in full. Read `AGENTS.md` / `CLAUDE.md` at the repo root and the nearest nested one to the code you're touching — they carry contracts you cannot infer from the code.
2. You are already on a fresh branch cut from `origin/main` — do not assume you are on `main`, and do not branch again from a local ref. Rename it to the repo's convention if it has one: `git branch -m <type>/<short-kebab-summary>`.
3. Build the ticket's end-to-end behaviour, and only that. Adjacent problems you spot get reported back, not fixed here.
   - Use the `matt/engineering/tdd` skill at the seams the spec names.
   - Run typechecking and **the affected test files by name** as you go — never the full gate. The whole suite is what step 5 is for, and running it as an inner loop is the single easiest way to spend half an hour proving the same thing repeatedly.
4. Review your own work with the `matt/engineering/code-review` skill, against the ticket as the spec axis. Fix what it finds.
5. Run `cursor-team-kit/deslop` to clean AI-specific slop patterns — unnecessary comments, defensive try/catch, `any` casts, deep nesting. Keep behavior unchanged.
6. **Regenerate whatever your change invalidated**: `<the repo's regeneration commands>`. A checked-in generated artifact that nobody regenerated is the one failure that is certain rather than probable, and it is the one CI cannot tell you anything you did not already know.
7. `git fetch origin && git rebase origin/main`, then run the **fast checks only** — `<fast check commands>` — plus, by name, the test files your change touches. **Do not run the full gate.** Then commit and open the PR with <the `create-pr` skill | `gh pr create`>. The PR body states what changed for a user and links the ticket (`Closes #<n>`).

**CI is the gate, and running it twice does not make it truer.** The full suite takes minutes, CI runs the identical command on the identical commit within a few minutes of the push, and the orchestrator is already watching for `checks-failed:` — so a local run buys a signal you are about to be handed for free, at the price of the slowest step in the whole ticket. What the fast checks and the regeneration above cover is the part CI would tell you about _late_: a type error, a lint finding, a stale generated file. What they do not cover is behaviour, and behaviour is what CI is for.

Push on green fast checks even if the full suite would have had more to say. **Do not push on a red one** — a type error or a lint finding is yours, it is seconds away from being fixed, and a PR opened with one is a round trip for something you could see.

If a check fails on something you did not touch — locally or in CI — see whether it also fails on a clean `origin/main` before debugging it. A broken base is the repo's problem to fix, not yours to absorb into this ticket; report it instead.

Stop and return a question instead of guessing when the ticket contradicts the spec, when the codebase has moved far enough that the ticket's approach no longer fits, or when a decision neither document made would change the interface.

Return, and nothing more:

- PR url, branch name, and the absolute path of this worktree (`git rev-parse --show-toplevel`) — the orchestrator removes it once the PR merges
- 3-5 sentences on what you built and any deliberate limitation
- anything the maintainer should look at closely
- **adjacent findings** — each problem you spotted and left alone, with the scope you believe it has and what fixing it would take. Name the files you checked, so the orchestrator can verify the scope before filing a ticket on it.

  **Do not file any of them.** Create no issues, open no tickets, edit nothing on the tracker beyond the PR link this ticket needs — filing is the maintainer's call and they have not been asked yet. A finding you file instead of report is one that skipped that question.

- questions, if you stopped for one
```

## Review-round brief

```markdown
You are addressing review feedback on PR #<n> in <repo path> (ticket <ticket ref>, spec <spec ref> — an absolute path if it is untracked, since your worktree holds only tracked files). You are in your own git worktree; work here and leave the main checkout alone.

1. Fetch and check out the PR branch in your worktree.
2. Gather every open thread: `gh pr view <n> --comments`, the inline threads
   (`gh api repos/<owner>/<repo>/pulls/<n>/comments`), and any failing checks
   (`gh pr checks <n>`).
3. Address each one. Group related fixes into one commit each, with the repo's commit conventions.
4. Reply to each thread with what changed, in one line. Leave the threads for the maintainer to resolve — that's the reviewer's call.
5. `git fetch origin && git rebase origin/main`, re-run the **fast checks** (`<fast check commands>`) and the test files the round touched, then push (`--force-with-lease` after a rebase). Not the full gate — CI runs it on the push, and the orchestrator is watching.

Fix everything you can. Escalate — leave the code untouched for that thread and report it — when a comment contradicts the ticket or the spec, forces a design decision neither document made, or asks for work outside this ticket's scope.

Return, and nothing more:

- one line per thread: what you changed, or why you escalated
- the gate result after your push
- whether the PR is now ready for another look
```
