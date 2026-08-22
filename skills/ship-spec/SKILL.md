---
name: ship-spec
description: Work every ticket in a spec through to merge — implement, PR, review, merge, sync, repeat — one ticket at a time, each in a fresh context, harvesting the follow-up tickets each merge turns up.
disable-model-invocation: true
---

# Ship a spec

Picks up where `/to-tickets` left off and runs the **frontier** — the tickets whose blockers are all done — until it is empty. One ticket at a time, each carried from implementation to a merged PR before the next one starts.

You are the **orchestrator**. You do not write the feature code: each ticket's implementation and each round of review fixes runs in a **fresh subagent**, so every ticket starts on a clean context and yours stays small enough to survive the whole spec. You hold the ledger; subagents hold the code.

**Merging is the maintainer's call.** You open the PR and wait for the human to merge it — `gh pr merge` is never yours to run.

## Guardrails

- **The tracker is the state.** Recompute the frontier from it every round. Keeping a private ledger of what's done invites drift, and a run that survives a `/clear` needs its state on the tracker anyway.
- **Each ticket gets its own branch off fresh `main`, in its own worktree** (see below). The main checkout stays on `main` for the whole run.
- **Run the frontier in parallel, but only where tickets cannot clash.** Dispatch several ready tickets at once when each one's files and declarations are disjoint; keep a ticket back and run it sequentially whenever it could collide. See **Parallelism** below — the clash test is not optional, and when you cannot answer it confidently the answer is sequential.
- **A round ends when its PRs are _open_, not when they merge.** Recompute the frontier and dispatch again the moment a ticket clears the clash test against everything still in flight. A run that waits for each merge before starting the next ticket puts CI and the maintainer's queue on the critical path of every ticket in turn — which is how a frontier of independent tickets comes to take as long as a chain of dependent ones.
- **Never file a ticket without being asked to, one finding at a time.** A harvested finding is a _proposal_ until the user approves that specific ticket in that specific message. Ask with `AskUserQuestion`; a silent tracker write is the one failure this skill will not recover from. See **Harvesting**.
- **Escalate contradictions.** When a ticket or a review comment fights the spec, or a decision the spec never made is forced, stop and ask the user with `AskUserQuestion`. Guessing is how a spec quietly becomes a different feature.
- **`/implement`, `/to-spec` and `/to-tickets` are user-invoked** (`disable-model-invocation: true`) — no skill can call them, including you. Their behaviour is inlined into the briefs in `SUBAGENT-BRIEF.md` instead. `/tdd`, `/code-review` and a project `create-pr` skill are model-invocable, so subagents invoke those directly.

## Process

### 1. Resolve the run

The argument is the spec: an issue number or URL, or a path to a `.scratch/<feature>/issues/` directory. With no argument, list the candidate specs you can find and ask which one.

Read the project's tracker config (`docs/agents/issue-tracker.md`) and follow the matching section of [`TRACKERS.md`](TRACKERS.md) for every tracker operation below. Then read the **spec in full** — it is the contract each ticket is measured against, and the only thing that outlives a subagent's context.

### 2. Preflight, once

- `git status --porcelain` is empty, and `main` is checked out and pulled. A dirty tree stops the run — report what's uncommitted and let the user deal with it. Agent worktrees are the exception: they live in `.claude/worktrees/`, which many repos do not ignore, so they surface as untracked and are not dirt.
- Find, from `AGENTS.md` / `CLAUDE.md`, four things, and put all four into every brief: the repo's **gate** command (`just ci`, `npm test`, …), its **fast checks** — lint, typecheck, build, whatever else runs in seconds and needs no database or container — its **regeneration** commands for checked-in generated artifacts, and its **stop** command for whatever the gate leaves running.
- **The gate is CI's to run, not the subagent's.** Time it once during the preflight and compare it with what CI takes; where they are within a few minutes of each other, running it locally before the push buys a signal that is already on its way and puts the slowest step of the ticket on its critical path. Measured on kobai: the gate is 3m20s locally, CI is 4–5 minutes, and the fast checks plus the artifact-drift tests are about 30 seconds and catch every failure that is _certain_ rather than probable. So the briefs ask for the fast checks and the regeneration; the full run happens once, on the PR. Say so in the go-ahead below, because it changes what an open PR means: a PR is now _proposed_ green, not proven green, and it is the watcher that closes that gap.
- Resolve any **untracked** material the briefs will cite — the spec itself, local agent overrides — to an absolute path in the main checkout, because a worktree will not contain it. `git check-ignore -v <path>` names the rule when you are unsure.
- Show the user the ordered ticket list, the gate, and the PR flow, and get one go-ahead for the whole run. **That go-ahead covers shipping these tickets and nothing else** — not filing a follow-up, not widening a ticket's scope, not merging.

### 3. The loop

Repeat until the frontier is empty.

**a. Pick the ticket.** Recompute the frontier from the tracker; take the first ticket whose blockers are all closed. Read its body now — not before.

**b. Resume check.** If that ticket already has an open PR (a previous run, or a run that got cleared), skip to **e** with that PR.

**c. Implement.** Run the clash test (see **Parallelism**) over the whole frontier, then dispatch a fresh `general-purpose` subagent with `isolation: "worktree"` and the implement brief from [`SUBAGENT-BRIEF.md`](SUBAGENT-BRIEF.md) for each ticket that clears it — in one message, so they run concurrently. Each returns a PR URL, a branch, and a short summary — or a question, which you escalate. Tickets that did not clear wait for the ones they would collide with to merge.

**d. Link it.** Record the PR on the ticket so a resumed run finds it, and mark the ticket in progress.

**d2. Go straight back to `a`.** Arm the watcher (**e**) and then recompute the frontier _immediately_ — do not wait for the merge. An open PR is out of your hands until an event arrives, and the twenty-odd minutes it spends in CI and in the maintainer's queue are minutes the next ticket could be using. Dispatch whatever now clears the clash test against every ticket still in flight; a ticket that clashes with one of them, or whose blocker is one of them, is the only kind that waits.

The loop is over when the frontier is empty **and** nothing is still being watched — not when the last ticket is dispatched.

**e. Watch the PR.** Arm the watcher through `Monitor` with `persistent: true` — `Monitor` **is** the harness's watching mechanism, and a PR can sit for hours, past any timeout:

```bash
~/.claude/skills/ship-spec/scripts/watch-pr.sh <pr-number>
```

It emits one line per state change and exits when the PR merges or closes. `Monitor` takes a command and has no PR-native mode, so that script is what fills the gap — emitting an event only when something moved is the difference between a handful of messages and one a minute. It is **shared with `/ship-ticket`**: both skills' `scripts/watch-pr.sh` are symlinks to `~/.claude/scripts/watch-pr.sh`, so fix it there and both skills get the fix. Never replace the symlink with a copy.

Use `Monitor` rather than a background `Bash` here — the watch emits many events over the PR's life, and a backgrounded command is the right tool only when you want a single notification at the end. When an event is the user's to act on (green and quiet, or closed without merging), `PushNotification` is what reaches them; an event line only reaches you.

**f. Handle each event.**

- `checks-failed:`, `review-activity:`, `review-decision: CHANGES_REQUESTED` → dispatch a fresh subagent, also with `isolation: "worktree"`, using the review-round brief; then keep watching. A new subagent per round is what keeps review fixes off a context that has already spent itself on the implementation.
- Green and quiet — no failing checks, no open threads → `PushNotification` the user **once** per PR: it is theirs to review.
- `merged:` → `git pull` in the main checkout, **tear down that ticket's worktree and the containers it left running** (below), confirm the ticket closed, **write its findings down for the harvest** (below), and recompute the frontier — a merge is what releases the tickets that were held back for clashing with it. With several PRs in flight, this is per-PR: touch only the merged ticket's worktree and branch, and leave the others watching.
- `closed-without-merge:` or `watch-error:` → stop and ask the user.

### 4. Report

Close with one line per ticket: number, title, PR, outcome. Name anything skipped or still open, and why. List the follow-ups you harvested, and the findings you declined to file.

## Parallelism

Several tickets in flight at once is the default when they are genuinely independent — it is most of the wall-clock saving this skill has to offer. It is also how two green PRs merge into a broken `main`, so the licence is narrow: **parallel only when the tickets cannot clash.**

Before dispatching a round, run the clash test over every ticket on the frontier. Two tickets clash when any of these is true:

- **Shared files.** They edit the same file — including the same generated artifact, the same guardrail test, the same doc page.
- **Shared declaration.** One moves, renames or absorbs something the other reads or writes against, even in a different file. A ticket that relocates a table and a ticket written against that table's old home clash, and neither diff shows it.
- **Ordered by design.** One is the other's blocker, or the tracker's dependency edge says so.
- **Same narrow surface.** Both change the behaviour of one command, one port method, or one config key from different angles, so the merged result is a behaviour neither PR reviewed.

Only the tickets that clear against _every_ already-dispatched ticket go out together; the rest wait. When you cannot answer the clash question confidently for a pair, they clash — the cost of being wrong is a broken `main` and a debugging session, and the cost of being cautious is one ticket's wall-clock.

Tell each subagent what the others own. Name the files the concurrent tickets are touching and instruct it to stop and report rather than edit one, so a surprise overlap surfaces as a question instead of a merge conflict.

Two practical consequences. Each agent runs the repo's full gate, so concurrent runs contend for the same machine and every gate gets slower — parallelism buys less than the ticket count suggests, and past a handful it buys nothing. And whichever PR merges second rebases onto the first: with a clean clash test that is a no-op, and when it is not, the clash test was wrong and is worth correcting before the next round.

## Worktrees

Every subagent runs in its own git worktree, so the main checkout stays on `main` for the whole run. Without it, each dispatch leaves the human's repo parked on whatever branch the last subagent was building, with its edits in the tree — and two agents cannot run at all.

**The harness makes the worktree, not you.** `isolation: "worktree"` on the dispatch is the whole of it: the harness creates one under `.claude/worktrees/<name>` on a branch of its own and pins the subagent's working directory to it. Never `git worktree add` one yourself, and **never call `EnterWorktree`** — that moves _your_ session into a worktree, which is the opposite of what this run needs, and it is gated on the user asking for it besides.

**A worktree holds only tracked files.** Everything git ignores is absent from it: a spec under an ignored path, `AGENTS.local.md` / `CLAUDE.local.md` overrides, any personal config the repo does not commit. `.git/info/exclude` is shared from the common directory, so the ignore _rule_ applies while the _file_ is missing — which is why this fails silently rather than loudly.

So anything the briefs cite that is not tracked goes in as an **absolute path into the main checkout**, marked read-only. Resolve those paths once during the preflight and reuse them in every brief. A repo-relative path resolves inside the worktree, where the file does not exist, and the subagent either reports it missing or works without it and never says so.

**Rebase on `origin/main` throughout, not just at branch time.** One ticket is in flight at a time, but `main` still moves underneath it — other sessions merge, the human pushes, a dependency lands. A branch cut hours ago and never refreshed is how two individually-correct PRs combine into a broken `main`: one renames a helper, the other was written against the old signature and merged without seeing it, and CI on each was green.

So the briefs tell the subagent to `git fetch origin` and rebase onto `origin/main` **before running the gate and again before opening the PR**, and review rounds do the same before pushing. A gate run against a stale base proves less than it appears to. After a rebase on a pushed branch, force-push with `--force-with-lease`.

**A worktree branches from `origin/main`, not from your checkout.** That is the `worktree.baseRef` setting and `fresh` is its default, so a stale local `main` does not reach the subagent and pulling first does not "give it a current base" — it already had one. Pull anyway, for the two things it _is_ load-bearing for: your own reading of the merged result, and checking `main` is green before you spend a ticket on it, since the subagent will report your repo's failure as if it were its own. Where a repo has set `baseRef: head`, the pull becomes the base too — check which you are on before trusting either sentence.

**Teardown is yours, and it needs the path.** The harness removes a worktree it made only when the agent left it _unchanged_, which a shipped ticket never does — so the directory survives the run and `.claude/worktrees/` accumulates one per ticket until somebody clears it. `ExitWorktree` will not do this: it only touches a worktree `EnterWorktree` made in this session, and this one was made by a dispatch. So the briefs return the worktree path, and you remove it with `git worktree remove` from the main checkout.

**Tear down at the merge, not before.** The branch and its worktree are how a resumed run picks a ticket back up mid-PR. Once the PR merges: remove the worktree, prune, delete the merged branch, and pull `main`. Run the removal from the main checkout — `git worktree remove` fails if the working directory is inside the worktree being removed. Remove only worktrees this run created, by exact path, and never with `--force` — another session's worktree may sit in the same directory.

**A worktree is not the only thing a ticket leaves behind, and the other one outlives it.** Where the repo derives a container stack per checkout — a compose project named from the worktree's path, which is what lets two checkouts run their gates at once — the subagent's gate started that stack and nothing stops it. Removing the worktree then orphans it: the databases stay up, holding RAM and CPU on the machine every later gate has to share, and once the path is gone there is nothing left to name them by. Observed on kobai: fifteen Postgres containers running, the oldest eighteen hours old, six of them belonging to worktrees that had already been torn down.

So **bring the stack down before you remove the directory**, in that order, from inside the worktree while its own environment still resolves — `devbox run down` and `devbox run db:down`, or `docker compose down -v`, whatever the repo's stop command is. If the directory is already gone, the containers are findable by their compose-project label and not otherwise:

```bash
docker ps -aq --filter "label=com.docker.compose.project=<project>" | xargs -r docker rm -f
docker volume ls -q --filter "label=com.docker.compose.project=<project>" | xargs -r docker volume rm
```

Add the stop command to the preflight alongside the gate command, so every ticket's teardown has it.

## Harvesting

Every implement brief tells the subagent to report adjacent problems rather than fix them, so each merge leaves a small pile of findings. **Write each one down as it arrives — one line, in your ledger beside the ticket — and harvest the pile once, at the end of the run.**

Harvesting at each merge is what this used to say, and it costs more than it looks. Every finding is an `AskUserQuestion`, every question is a human round trip, and the frontier stands still for the length of it — so a spec's wall-clock came to include the maintainer's response time once per finding, on a loop whose whole design is that tickets do not wait for each other. Held to the end, the questions are answered while nothing is pending, and the answers are better besides: by then the run knows whether a later ticket absorbed the finding, and whether the scope the subagent claimed for it held up across the rest of the spec.

The one thing that trades away is durability — a finding lives in your context until it is asked about. So **if your context is going before the frontier empties, harvest what you are holding then** rather than losing it. That is the only reason to interrupt the loop for this.

**Verify a finding before you file it.** A subagent reports what it saw from inside one ticket, and the scope it names is often wrong — one run reported a two-platform problem that a later ticket found on three. Check it against the code yourself. The ticket is only as good as the facts in it, and a wrong count sends the next agent down the wrong path.

**Search the tracker before proposing anything.** A finding surfaced from inside one ticket looks novel from in there and often is not — the repo may already have an issue for it, possibly with a PR in flight. Search by the symptom and by the file, not by the wording you would use for the title.

**The user decides what gets filed, every time, one finding at a time.** Present the survivors as a short list — one line each: what it is, why it qualifies, the title you would give it — then **stop and ask with `AskUserQuestion`**, and wait for an answer. Nothing is written to the tracker before that answer arrives.

Four things this rules out, because each is a way a run files a ticket nobody asked for:

- **No batch yes.** Approval covers the one finding it names. Three findings is three answers, even when the user said "yes" quickly to the first two.
- **No standing approval.** The go-ahead for the run does not extend to filing, a previous round's approval does not carry to this one, and neither does approval given for a finding that turned out to be a different finding on inspection.
- **No inferred yes.** Silence, "sounds good", "makes sense", or a reply about something else is not approval. Only an answer to the question you asked, about the ticket you described, is.
- **No filing on the way past.** Not while closing out a merge, not while writing the final report, not "so it isn't lost". A finding the user declined or never ruled on goes in the report as prose and nowhere else.

Approval to file is also not approval to do the work: file the ticket, say so, and leave it on the tracker. Filing is cheap to do and tedious to undo, and a tracker filling up with an agent's by-products is the failure mode this guards against.

Propose a finding when it is real, outlives this spec, and no open ticket covers it. Leave it where it is when:

- **A decision already ruled on it.** A finding that reopens what the spec, an ADR, or an earlier grill settled is not new information.
- **It is the first step of work nobody has designed yet.** That is scope creep wearing a ticket's clothes — name it in your report and let the human decide whether it earns its own design pass.
- **The ticket in flight already absorbed it.**

Filed tickets go on the tracker, never in your head: the frontier is recomputed from there, so a follow-up joins the queue by construction. Give it a blocking edge only where one genuinely exists — most follow-ups are independent and run last.

Report both halves, with a reason each. The declines are the more useful half — they are the record of what the run decided _not_ to do, and without them the same finding comes back next spec as a fresh idea.

## Escalating

Stop the loop and ask when:

- A review comment contradicts the ticket or the spec.
- Two tickets disagree about the same interface — the spec needs a ruling, not a coin flip.
- The gate stays red after the subagent's own attempts to fix it.
- A ticket's blockers never clear (a blocker was closed without merging, or the edges are cyclic).
- The PR is closed without merging.

## When your own context fills

Everything needed to resume lives on the tracker: which tickets are closed, which are in progress, and their PRs. Tell the user to `/clear` and re-invoke `/ship-spec` with the same spec reference — the resume check in **3b** picks the run up mid-PR.

To delay that as long as possible, keep only ticket numbers, statuses, PR numbers and one-line outcomes in your context — with several tickets in flight this matters more, not less, since each returns its own report. Read ticket bodies at dispatch time, and let the subagents' return values stay summaries — never ask one for a diff.
