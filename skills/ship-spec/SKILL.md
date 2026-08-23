---
name: ship-spec
description: "Iterate every ticket in a spec through to merge until the feature ships."
---

# Ship Spec

Iterate through every ticket in a spec, running the same script per ticket, until the whole feature ships.

## Process

1. Dispatch a **quick** subagent to verify clean state:

   ```
   git status --porcelain
   ```

   If dirty, stop: "working directory is dirty — commit or stash first".

2. Resolve the spec:
   - **No argument:** dispatch a **quick** subagent to list open specs: `gh issue list --label type:spec --state open --limit 20` and ask the user which one.
   - **Issue number:** dispatch a **quick** subagent to read it: `gh issue view <n> --json title,body,labels` and proceed.

3. Dispatch a **quick** subagent to read all tickets for this spec: `gh issue list --label type:ticket --state open --json number,title,body,labels --limit 50`

4. **Cluster and sort.**
   Group by blocked-by graph into parallel clusters. For each cluster, order tickets so the most load-bearing one comes first.
   One wrong ticket at the root can invalidate the rest — find that one and ship it first, while the context window is fresh and the tooling is trusted.

5. **Ask the user** for confirmation before proceeding. Correctness-first ordering matters more than speed.

6. **For each ticket,** dispatch a **quick** subagent to check the branch: `gh pr list --head <ticket-branch> --state open --json number`
   - If a PR already exists, ask the user: **resume**, **skip**, or **redo**.
   - Otherwise, dispatch `/ship-ticket` for that ticket.

7. **After each merge,** dispatch a **quick** subagent to sync open tickets: `gh issue list --label type:ticket --state open --json number,title,body,labels --limit 50`

   Look for:
   - Tickets blocked by the one you just merged → update status to `status:ready-for-agent`
   - Conflicts from changes you just landed
   - New blocking edges that only exist now that the merged code is in main

   Flags are rare — but if you skip this step, each ticket becomes a small bet that nothing you landed surprised you. Re-checking after every merge keeps the next ticket grounded in the actual state of the code, not the state you expected. Ask the user what to do.

8. **After all tickets are merged,** dispatch a **quick** subagent to run the watcher script: `bash ~/.claude/scripts/watch-pr.sh --sync` and report results.

9. Present the summary: what was shipped, what was skipped, what needs human attention.

## Clash test (before each ticket)

Before dispatching `/ship-ticket`, dispatch a **quick** subagent to assess risk of parallel work:

```
gh pr list --state open --json number,title,headRefName,files --limit 20
```

- **No file overlap** (excluding lockfiles): safe to proceed.
- **Overlaps a merged-but-unreleased PR** or the last 3 merged PRs: warn, ask user to confirm.
- **Lockfiles only:** usually merge conflict — tell the user, don't resolve.

## Traversal order

Dispatch a **quick** subagent to read the git graph of recent merged PRs:

```
git log --oneline -10
```

If a ticket was cut before its dependency merged (detected by date or checkout history), dispatch `/ship-ticket` for the dependent ticket first — the earlier work may be the stale revision.

## Retry / failure

If `/ship-ticket` reports that the ticket cannot land:

- Read the failure report
- Classify: **stale spec**, **failed CI**, **code issue**, **dependency**, **other**
- Dispatch a **quick** subagent to reassign the ticket: `gh issue edit <n> --add-label "status:blocked" --remove-label "status:in-progress"`
- Dispatch a **quick** subagent to comment the reason: `gh issue comment <n> --body "<reason>"`
- Move to the next ticket, or ask the user if this ticket is load-bearing

Do not let one failing ticket stop the whole spec. Route around it.

## Completion

Done when every ticket in the spec is merged, or the user declares the spec complete. Checkable: dispatch a **quick** subagent to verify no open `type:ticket` sub-issues remain under the spec.
