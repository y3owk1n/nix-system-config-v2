---
name: ship
description: "Ship a spec or a single ticket from start to merged PR."
---

# Ship

Two modes. **Spec mode** loops every ticket under a spec. **Ticket mode** ships one.

**Merging is the maintainer's call.** You open the PR and wait. `gh pr merge` is never yours to run.

Tracker operations: `TRACKERS.md`. Parallel worktree briefs: `SUBAGENT-BRIEF.md`.

## Drift check — first thing, both modes

Before any ticket is touched:

```
gh issue view <spec> --json body
```

The stamp in the body carries **both halves**: `<!-- prd-source: prd/features/<slug>.md@<blob-sha> -->`. Read the path from it — never guess the slug from the issue title. Then:

```
git hash-object <the path from the stamp>
```

Compare that hash to the one in the stamp. On a mismatch the feature file moved and the spec issue is stale — re-render it with `spec/SPEC-RENDER.md` and `gh issue edit <spec> --body`, in place, same issue number. Then check whether the change invalidates any open ticket and tell the user which.

Skip nothing here. A stale spec makes every ticket below it a small bet that nothing changed.

## Spec mode

1. `git status --porcelain` — dirty tree stops the run.
2. Resolve the spec. No argument: `gh issue list --label type:spec --state open --limit 20`, ask which.
3. Drift check (above).
4. Read the tickets: `gh issue view <spec> --json subIssues`, then each one.
5. **Cluster and sort.** Group by blocking edges. Within a cluster, the most load-bearing ticket goes first — one wrong ticket at the root invalidates the rest, and you want it wrong early while the context is fresh.
6. Confirm the order with the user. This is the one stop in spec mode.
7. For each ticket in order: check for an existing PR (`TRACKERS.md`, resume check). Existing PR means ask **resume / skip / redo**. Otherwise run ticket mode, skipping its step 1 drift check and step 2 blocker check — both were settled here.
8. After each merge, recompute the frontier and promote unblocked tickets to `status:ready-for-agent`. Report anything the merge surprised you with; do not silently absorb it.
9. Summary: shipped, skipped, needs a human.

**A failing ticket does not stop the spec.** Classify it — stale spec, failed CI, code issue, dependency, other — label it `status:blocked` with a comment saying which, and route around it. Ask the user only if the ticket is load-bearing for the rest.

## Ticket mode

1. **Read the ticket and its spec.** `gh issue view <n> --json title,body,labels,state,parent`. The spec is the contract the work is measured against.

   **Drift-check the parent** before reading it, using the section above — unless spec mode already did it for this run. A ticket measured against a stale spec fails in the way that is hardest to see: everything passes, against the wrong contract.

   A ticket with no parent is measured against itself — say that out loud in the preflight so the user can correct you. Ambiguity in the spec is a question, not a guess.

   Note the ticket's **behaviours touched**. That list is the entire test budget for this ticket.

2. **Check blockers and prior runs.** Both queries are in `TRACKERS.md`.

   An **open blocker** stops the run: report which ticket gates this one and let the user decide whether to ship that first. Skip when spec mode ordered the run — the frontier was computed there.

   An **existing PR** on this ticket means a previous run got partway. Ask **resume / skip / redo** rather than branching over the top of it.

3. **Preflight and branch.** `git status --porcelain` — a dirty tree stops the run. Then `git fetch origin && git switch -c ticket/<short-kebab-summary> origin/main`.

   Branch from `origin/main`, not a local `main` that may be behind. Read the files at the seams the spec names — not the whole subsystem.

   Look for a prefactor that makes the change easy. If you find one, it is a separate commit that lands first.

4. **Implement.** Dispatch `/implement` per unit. The review happens inside `/implement`, inline, using the review rules already in your context — there is no separate review dispatch.

5. **PR.** Dispatch `/pr` — it owns the commit format, the staging discipline, and the attribution guardrails. Give it the ticket number so the body carries `Closes #<n>`.

   PRD edits this ticket produced are their own commit, `docs(prd): <what>`, in this same PR. Proposed `behaviours.md` entries go in the **PR body**, never in the file.

6. **Gate.** `gh pr checks <pr> --required`. Fix failures yourself. Do not hand it to a human red.

7. **Ask the user to review.** Then address comments and return to the gate.

8. **Merged.** `git checkout main && git pull && git branch -d <branch>`. Confirm the ticket closed.

9. **PRD delta.** What did this ticket establish that the PRD did not predict? A new term, a decision that was hard to reverse, a moved boundary. Dispatch `/prd` in **update** mode. Nothing to record is a valid answer — say it and stop.

   If the ticket contradicted the spec, that is the most important thing you learned. Say so explicitly.

## What this skill deliberately does not do

- **No clash test.** Checking `gh pr list --files` for overlap guards a multi-developer repo. If that changes, it comes back.
- **No separate `/review` dispatch.** The rubric is in your context; `/implement` applies it inline. `/review` stays available for reviewing something manually, outside a ticket.
- **No harvest ritual.** Step 9 replaces it, and it lands in the same PR rather than as a follow-up nobody writes.

## Completion

Spec mode: every ticket merged, or explicitly blocked with a reason. Ticket mode: PR merged, ticket closed, branch deleted, PRD delta applied or explicitly skipped. Checkable: `gh pr view <pr> --json state` is `MERGED` and the local branch is gone.
