# Tracker operations

Four operations drive the loop, whatever the tracker: **list the tickets**, **compute the frontier**, **record a PR on a ticket**, **confirm a ticket is done**. `docs/agents/issue-tracker.md` says which tracker this repo uses; follow that section. Anything it states beyond these operations — repo-specific labels, a project `create-pr` skill, PR conventions — wins over what's here.

## GitHub (`gh`)

The spec is an issue. Each ticket is its own issue carrying a `## Parent` section that references the spec — `/to-tickets` writes that link as text, so a spec's tickets are found by search, not by the native `parent` field (which stays empty unless the repo uses sub-issues).

- **List** — `gh issue list --state all --limit 50 --search "<spec-number> in:body" --json number,title,state`, then keep the issues whose body really has `## Parent` → the spec, dropping the spec issue itself. Where a repo does use sub-issues, `gh issue view <spec> --json subIssues` is the exact answer.

  Ascending issue number **is** dependency order — `/to-tickets` publishes blockers first.

- **Frontier** — `gh issue view <n> --json blockedBy` returns each blocker with its state, so a ticket is ready when no blocker is `OPEN`:

  ```bash
  gh issue view <n> --json number,blockedBy \
    --jq 'if [.blockedBy.nodes[]? | select(.state == "OPEN")] == [] then "ready" else "blocked" end'
  ```

  Prefer this over the REST `issue_dependencies_summary` — one call, and it names the blockers rather than counting them. Where a repo has no dependency links, parse the `Blocked by: #n` line in the body and check each referenced issue is closed.

- **Resume check** — `gh issue view <n> --json closedByPullRequestsReferences` lists linked PRs on **open** issues too, so an open ticket with a PR there is a run to pick up rather than restart. Confirm with `gh pr view <pr> --json state,isDraft`.

- **Record a PR** — the `Closes #<n>` line in the PR body creates that link. Add `gh issue edit <n> --add-assignee @me` so the ticket also reads as in flight to a human.

- **Done** — the issue is closed, which `Closes #<n>` does on merge. If it is still open after the merge, close it yourself.

## Local markdown

Tickets are files under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered in dependency order.

- **List** — the files, in numeric order.
- **Frontier** — read each file's `**Blocked by:**` line; a ticket is ready when every ticket it names has `**Status:** done`.
- **Record a PR** — set `**Status:** in-progress` and append a `**PR:** <url>` line.
- **Done** — set `**Status:** done`. Commit the status change with the merge, so the ledger and the code move together.

The resume check is the `**PR:**` line on an `in-progress` ticket.

## GitLab (`glab`)

As GitHub, with `glab issue` / `glab mr` in place of `gh issue` / `gh pr`, and merge requests in place of pull requests. Blocking edges are GitLab's **blocked by** links (`glab api` on the issue links endpoint) or the same `Blocked by:` body line as a fallback.

## Anything else

`docs/agents/issue-tracker.md` records the workflow as prose. Map the four operations onto it before starting, and confirm the mapping with the user in the preflight — a wrong frontier query silently works the wrong ticket first.
