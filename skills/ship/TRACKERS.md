# Tracker operations

GitHub, via `gh`. Four operations drive a run: **read**, **compute the frontier**,
**record a PR**, **confirm done**.

The spec is an issue. Tickets are its **sub-issues** — `/spec` publishes them with
`gh issue create --parent`, so the native link is real and search is never needed.

## Read

```bash
gh issue view <n> --json number,title,state,body,labels,parent
gh issue view <spec> --json subIssues
```

Ascending issue number is dependency order: `/spec` publishes blockers first.

## Frontier

A ticket is ready when no blocker is open:

```bash
gh issue view <n> --json number,blockedBy \
  --jq 'if [.blockedBy.nodes[]? | select(.state == "OPEN")] == [] then "ready" else "blocked" end'
```

One call, and it names the blockers rather than counting them. Where a repo has no
dependency links, parse the `Blocked by: #n` line in the body and check each is closed.

An open blocker stops a ticket-mode run: report it and let the user decide whether to
ship that one first. In spec mode the ordering already handles it.

## Resume check

```bash
gh issue view <n> --json closedByPullRequestsReferences
```

This lists linked PRs on **open** issues too, so an open ticket with a PR is a run to
pick up rather than restart. Confirm with `gh pr view <pr> --json state,isDraft`.

## Record a PR

The `Closes #<n>` line in the PR body creates the link. Add
`gh issue edit <n> --add-assignee @me` so the ticket reads as in flight to a human.

## Done

The issue closes on merge via `Closes #<n>`. If it is still open afterwards, close it.

## Not GitHub

There is no local-markdown mode. `prd/features/<slug>.md` is the offline artefact, and
duplicating the tracker into `.scratch/` was the drift this workflow exists to remove.

For GitLab, substitute `glab issue` / `glab mr` and treat merge requests as pull
requests; blocking edges are GitLab's **blocked by** links. Confirm the mapping with the
user in the preflight before starting — a wrong frontier query silently works the wrong
ticket first.
