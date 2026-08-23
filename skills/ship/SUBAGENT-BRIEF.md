# Subagent briefs

Two briefs, both for a `general-purpose` subagent in its own git worktree. Each is written for a **fresh context**: the subagent has never seen the PRD, the ticket, or your conversation, so everything it needs must be in the brief or reachable from a reference it can fetch itself.

Fill every `<…>` before dispatching. Pass references — issue numbers, paths — not pasted bodies. The subagent fetching them keeps your context clear and its copy current.

Use these only when shipping tickets in parallel. A single ticket is cheaper to run inline.

## Implement brief

```markdown
You are implementing one ticket in <repo path>. You are in your own git worktree on a clean checkout of `main` — work here and leave the main checkout alone.

Ticket: <issue number>
Spec: <spec issue number>

1. Read the ticket and the spec in full. Read `prd/glossary.md`, `prd/behaviours.md`, and `prd/architecture.md` if they exist — they carry contracts you cannot infer from the code. Read `CLAUDE.md` / `AGENTS.md` at the repo root and the nearest nested one to the code you are touching.

2. You are already on a fresh branch cut from `origin/main` — do not assume you are on `main` and do not branch again from a local ref. Rename to the repo's convention: `git branch -m ticket/<short-kebab-summary>`.

3. Build the ticket's end-to-end behaviour, and only that. Adjacent problems you spot get reported back, not fixed here.

   **Tests.** The ticket's `## Behaviours touched` section is your entire test budget. Write a test only for a behaviour listed there, at the highest seam the spec names, and name the test after the behaviour. A ticket claiming no behaviours gets no new test file — that is correct, not an oversight to correct.

   Never assert the toolchain works: no install, build, compile, lint, file-exists, or config-parses tests. Never mirror implementation.

   Run typechecking and **the affected test files by name** as you go — never the full gate. Running the whole suite as an inner loop is the easiest way to spend half an hour proving the same thing repeatedly.

4. Review your own diff against the review rules in your context: the Standards axis (conventions, naming, structure, types, error handling, security) and the Spec axis (does it do what the ticket says, no more). Fix what you find.

5. Run `/cursor-team-kit_deslop` — unnecessary comments, defensive try/catch, `any` casts, deep nesting. Behaviour unchanged.

6. **Regenerate whatever your change invalidated**: <the repo's regeneration commands>. A checked-in generated artefact nobody regenerated is the one failure that is certain rather than probable, and the one CI cannot tell you anything new about.

7. `git fetch origin && git rebase origin/main`, run the **fast checks only** — <fast check commands> — plus, by name, the test files your change touched. **Not the full gate.** Then commit and open the PR with <the `pr` skill | `gh pr create`>. The body states what changed for a user and links the ticket (`Closes #<n>`).

**CI is the gate, and running it twice does not make it truer.** The suite takes minutes; CI runs the identical command on the identical commit within minutes of the push, and the orchestrator is already watching. A local full run buys a signal you are about to be handed for free, at the price of the slowest step in the ticket. The fast checks and the regeneration cover what CI would tell you _late_ — a type error, a lint finding, a stale artefact. What they do not cover is behaviour, and behaviour is what CI is for.

Push on green fast checks. **Do not push on a red one** — a type error is yours, seconds from being fixed, and a PR opened with one is a round trip for something you could see.

If a check fails on something you did not touch, see whether it also fails on a clean `origin/main` before debugging. A broken base is the repo's problem, not yours to absorb into this ticket. Report it.

Stop and return a question instead of guessing when the ticket contradicts the spec, when the codebase has moved far enough that the ticket's approach no longer fits, or when a decision neither document made would change an interface.

Return, and nothing more:

- PR url, branch name, and this worktree's absolute path (`git rev-parse --show-toplevel`) — the orchestrator removes it once the PR merges
- 3-5 sentences on what you built and any deliberate limitation
- anything the maintainer should look at closely
- **PRD delta** — new or sharpened terms for `glossary.md`, decisions worth `decisions.md`, moved boundaries for `architecture.md`. Propose entries for `behaviours.md`; **never edit that file**.
- **adjacent findings** — each problem you spotted and left alone, its scope, and what fixing it would take. Name the files you checked so the orchestrator can verify the scope.

  **File none of them.** Create no issues, edit nothing on the tracker beyond this ticket's PR link. Filing is the maintainer's call and they have not been asked.

- questions, if you stopped for one
```

## Review-round brief

```markdown
You are addressing review feedback on PR #<n> in <repo path> (ticket <n>, spec <n>). You are in your own git worktree; work here and leave the main checkout alone.

1. Fetch and check out the PR branch in your worktree.
2. Gather every open thread: `gh pr view <n> --comments`, the inline threads (`gh api repos/<owner>/<repo>/pulls/<n>/comments`), and failing checks (`gh pr checks <n>`).
3. Address each. Group related fixes into one commit each, following the repo's commit conventions.
4. Reply to each thread with what changed, in one line. Leave threads for the maintainer to resolve — that is the reviewer's call.
5. `git fetch origin && git rebase origin/main`, re-run the **fast checks** (<fast check commands>) and the test files this round touched, then push (`--force-with-lease` after a rebase). Not the full gate — CI runs it on the push.

Fix everything you can. Escalate — leave that thread's code untouched and report it — when a comment contradicts the ticket or spec, forces a design decision neither document made, or asks for work outside this ticket.

Return, and nothing more:

- one line per thread: what changed, or why you escalated
- the gate result after your push
- whether the PR is ready for another look
```
