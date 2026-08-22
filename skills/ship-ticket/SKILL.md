---
name: ship-ticket
description: Work one ticket through to merge in this session — implement it, open the PR, run the review rounds, and harvest the follow-ups the merge turns up. The single-ticket sibling of /ship-spec; reach for it when there is one issue to land rather than a whole spec.
disable-model-invocation: true
---

# Ship a ticket

Takes **one** ticket from where it sits on the tracker to a merged PR. Nothing else — no frontier, no queue, no next ticket. When the PR merges, the run is over.

This is `/ship-spec` with the loop taken out, and with it the orchestration. **You do the work yourself, in this session, on a branch in the main checkout.** One ticket does not need a subagent: dispatching one would buy a clean context and cost you every detail of the implementation at exactly the moment review feedback arrives asking about it. `/ship-spec` pays that price because it ships many tickets and cannot hold them all; you are shipping one.

**Merging is the maintainer's call.** You open the PR and wait for the human to merge it — `gh pr merge` is never yours to run.

## Guardrails

- **The tracker is the state.** The ticket's status and its linked PR are what a resumed run reads. Keeping a private ledger invites drift, and a run that survives a `/clear` needs its state on the tracker anyway.
- **One ticket.** If the ticket turns out to need another one landed first, stop and say so — do not quietly ship the blocker too. Shipping the queue is `/ship-spec`'s job.
- **Never file a ticket without being asked to, one finding at a time.** A harvested finding is a _proposal_ until the user approves that specific ticket in that specific message. Ask with `AskUserQuestion`; a silent tracker write is the one failure this skill will not recover from. See **Harvesting**.
- **Escalate contradictions.** When the ticket or a review comment fights the spec it came from, or forces a decision nobody has made, stop and ask the user with `AskUserQuestion`. Guessing is how a ticket quietly becomes a different feature.
- **`/implement`, `/to-spec` and `/to-tickets` are user-invoked** (`disable-model-invocation: true`) — no skill can call them, including you. What `/implement` would have done is written out in step 4 instead. `/tdd` and `/code-review` are model-invocable, and so is a project `create-pr` skill, so invoke those directly.

## Process

### 1. Resolve the ticket

The argument is the ticket: an issue number or URL, or a path to a ticket file. With no argument, list the open tickets you can find and ask which one.

Read the project's tracker config (`docs/agents/issue-tracker.md`) and follow the matching section of [`TRACKERS.md`](TRACKERS.md) for every tracker operation below. Then read the **ticket in full**.

**Find its spec, if it has one.** A ticket written by `/to-tickets` carries a `## Parent` section pointing at the spec issue; a ticket filed by hand may reference an ADR or a design doc instead, or nothing. Read whatever it names — that is the contract the work is measured against. A ticket with no parent is measured against itself, which is fine, and worth saying out loud in the preflight so the user can correct you.

**Check the blockers.** If the ticket names blockers that are still open, stop and report them. One ticket whose foundations are missing is not a run to start.

### 2. Preflight

- `git status --porcelain` is empty, and `main` is checked out and pulled. A dirty tree stops the run — report what's uncommitted and let the user deal with it.
- `main` is actually green. Starting a ticket on a broken base wastes the work and disguises the repo's failure as yours.
- Find the repo's gate command from `AGENTS.md` / `CLAUDE.md` (`just ci`, `npm test`, …), and whether a project `create-pr` skill exists.
- Show the user the ticket, the spec it is measured against (or that there is none), the gate, and the PR flow, and get one go-ahead. **That go-ahead covers shipping this ticket and nothing else** — not filing a follow-up, not widening the ticket's scope, not merging.

### 3. Resume check

If the ticket already has an open PR — a previous run, or one that got cleared — check out that branch and skip to **6**. A half-shipped ticket is picked up, never restarted.

### 4. Implement

Work on a branch in the main checkout: `git fetch origin && git switch -c <type>/<short-kebab-summary> origin/main`. Branching from `origin/main` rather than from local `main` is what makes the pull in the preflight a convenience rather than a correctness step.

1. Read `AGENTS.md` / `CLAUDE.md` at the repo root and the nearest nested one to the code you're touching — they carry contracts you cannot infer from the code.
2. Build the ticket's end-to-end behaviour, and only that. **Adjacent problems get written down, not fixed** — that list is what **Harvesting** collects at the merge, and a fix that rides along is a fix nobody reviewed against a ticket.
   - Use the `matt/engineering/tdd` skill at the seams the ticket names.
   - Run typechecking and **the affected test files by name** as you go — never the full gate. The whole suite is what step 4 is for, and running it as an inner loop is the easiest way there is to spend half an hour proving the same thing repeatedly.
3. Review your own work with the `matt/engineering/code-review` skill, against the ticket as the spec axis. Fix what it finds.
4. **Regenerate whatever the change invalidated** — every checked-in generated artifact the repo compares byte for byte. That is the one failure that is certain rather than probable, and the one CI cannot tell you anything you did not already know.
5. `git fetch origin && git rebase origin/main`, then run the **fast checks** — lint, typecheck, build, whatever else runs in seconds without a database or a container — plus, by name, the test files this ticket touched. **Do not run the full gate.** If something fails on code you did not touch, check whether it also fails on a clean `origin/main` before debugging it — a broken base is the repo's problem, not this ticket's to absorb.

**CI is the gate, and running it twice does not make it truer.** The full suite takes minutes, CI runs the identical command on the identical commit a few minutes after the push, and step 6 is already watching for `checks-failed:` — so a local run buys a signal that is on its way, at the price of the slowest step in the ticket. The fast checks cover what CI would otherwise tell you _late_: a type error, a lint finding, a stale generated file. Behaviour is what CI is for. **Push on green fast checks; never on a red one** — a type error is yours, it is seconds from being fixed, and a PR opened with one is a round trip for something you could see.

### 5. Open the PR

Commit and open the PR — with the project's `create-pr` skill if it has one, otherwise `gh pr create`. The body states what changed for a user and links the ticket (`Closes #<n>`).

**Do not re-run the gate here.** If `origin/main` moved between step 4 and this one, push anyway and let CI answer: it is the same gate on the same commit, it is already going to run, and a second local pass buys a signal you are about to be handed for free. The rebase in step 4 is what makes the base current; a second one is only worth taking if the merge itself conflicts.

Then **link it**: record the PR on the ticket so a resumed run finds it, and mark the ticket in progress.

### 6. Watch the PR

Arm the watcher through `Monitor` with `persistent: true` — `Monitor` **is** the harness's watching mechanism, and a PR can sit for hours, past any timeout:

```bash
~/.claude/skills/ship-ticket/scripts/watch-pr.sh <pr-number>
```

It emits one line per state change and exits when the PR merges or closes. `Monitor` takes a command and has no PR-native mode, so that script is what fills the gap — emitting an event only when something moved is the difference between a handful of messages and one a minute. It is **shared with `/ship-spec`**: both skills' `scripts/watch-pr.sh` are symlinks to `~/.claude/scripts/watch-pr.sh`, so fix it there and both skills get the fix. Never replace the symlink with a copy.

Use `Monitor` rather than a background `Bash` here — the watch emits many events over the PR's life, and a backgrounded command is the right tool only when you want a single notification at the end. When an event is the user's to act on (green and quiet, or closed without merging), `PushNotification` is what reaches them; an event line only reaches you.

Handle each event:

- `checks-failed:`, `review-activity:`, `review-decision: CHANGES_REQUESTED` → run a review round (**7**), then keep watching.
- Green and quiet — no failing checks, no open threads → `PushNotification` the user **once**: the PR is theirs to review.
- `merged:` → `git switch main && git pull`, delete the merged branch, confirm the ticket closed, **harvest the findings** (below), and report (**8**).
- `closed-without-merge:` or `watch-error:` → stop and ask the user.

### 7. Review rounds

Stay on the branch and fix them here.

1. Gather every open thread: `gh pr view <n> --comments`, the inline threads (`gh api repos/<owner>/<repo>/pulls/<n>/comments`), and any failing checks (`gh pr checks <n>`).
2. Address each one, grouping related fixes into a commit each, with the repo's commit conventions.
3. Reply to each thread with what changed, in one line. **Leave the threads for the maintainer to resolve** — that is the reviewer's call, not yours.
4. `git fetch origin && git rebase origin/main`, re-run the gate, then push (`--force-with-lease` after a rebase).

Fix everything you can. **Escalate** — leave that thread's code untouched and ask — when a comment contradicts the ticket or its spec, forces a design decision neither document made, or asks for work outside this ticket's scope.

**Rebase every round, not just at branch time.** A ticket takes as long as its review rounds take, and `main` moves underneath it the whole while — other sessions merge, the human pushes, a dependency lands. A branch cut hours ago and never refreshed is how two individually-correct PRs combine into a broken `main`: one renames a helper, the other was written against the old signature and merged without seeing it, and CI on each was green. A gate run against a stale base proves less than it appears to.

### 8. Report

Close with the ticket number and title, the PR, and the outcome. Name what the implementation deliberately left out, anything the maintainer should look at closely, and how many review rounds it took. List the follow-ups you harvested, and the findings you declined to file.

## Harvesting

Step 4 says adjacent problems get written down rather than fixed, so the merge leaves a small pile of findings. Harvest them **at the merge**, while the work is still fresh — a finding not acted on then dies with your context.

**Verify a finding before you propose it.** What looked like a two-file problem from inside the ticket is often wider or narrower. Check it against the code now that you are out of the change. The ticket is only as good as the facts in it, and a wrong scope sends the next person down the wrong path.

**Search the tracker before proposing anything.** A finding surfaced from inside one ticket looks novel from in there and often is not — the repo may already have an issue for it, possibly with a PR in flight. Search by the symptom and by the file, not by the wording you would use for the title.

**The user decides what gets filed, every time, one finding at a time.** Present the survivors as a short list — one line each: what it is, why it qualifies, the title you would give it — then **stop and ask with `AskUserQuestion`**, and wait for an answer. Nothing is written to the tracker before that answer arrives.

Four things this rules out, because each is a way a run files a ticket nobody asked for:

- **No batch yes.** Approval covers the one finding it names. Three findings is three answers, even when the user said "yes" quickly to the first two.
- **No standing approval.** The go-ahead for the run does not extend to filing, a previous round's approval does not carry to this one, and neither does approval given for a finding that turned out to be a different finding on inspection.
- **No inferred yes.** Silence, "sounds good", "makes sense", or a reply about something else is not approval. Only an answer to the question you asked, about the ticket you described, is.
- **No filing on the way past.** Not while closing out a merge, not while writing the final report, not "so it isn't lost". A finding the user declined or never ruled on goes in the report as prose and nowhere else.

Approval to file is also not approval to do the work: file the ticket, say so, and leave it on the tracker. Filing is cheap to do and tedious to undo, and a tracker filling up with an agent's by-products is the failure mode this guards against.

Propose a finding when it is real, outlives this ticket, and no open ticket covers it. Leave it where it is when:

- **A decision already ruled on it.** A finding that reopens what the spec, an ADR, or an earlier grill settled is not new information.
- **It is the first step of work nobody has designed yet.** That is scope creep wearing a ticket's clothes — name it in your report and let the human decide whether it earns its own design pass.
- **The ticket already absorbed it.**

Report both halves, with a reason each. The declines are the more useful half — they are the record of what the run decided _not_ to do, and without them the same finding comes back next time as a fresh idea.

## Escalating

Stop and ask when:

- A review comment contradicts the ticket or the spec it came from.
- The ticket turns out to depend on work that has not landed.
- The gate stays red after your own attempts to fix it.
- The PR is closed without merging.

## When your own context fills

Doing the work here rather than in a subagent spends your context on the implementation, so this is the run's real limit — and the reason it is safe is that **nothing lives only in your head**. The branch is pushed, the PR is open, the ticket links it, and the findings you have not harvested yet are the ones you wrote down.

When the context is going: push what you have, make sure the PR exists and the ticket links it, then tell the user to `/clear` and re-invoke `/ship-ticket` with the same ticket reference. The resume check in **3** checks the branch back out and picks up at the watch.

To delay that: keep the reading you do proportionate to the ticket, and do not re-read files you have already changed — the edit tools error rather than silently failing, so a re-read to confirm a change landed buys nothing.

**If the implementation is plainly too big for one context** — a ticket touching many packages, a migration across a whole surface — say so at the preflight rather than discovering it at 80%. That is what `/ship-spec` is for, and a ticket that large is usually a spec that was never split.
