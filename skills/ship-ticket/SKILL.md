---
name: ship-ticket
description: "Ship one ticket from start to merged PR."
---

# Ship Ticket

**Merging is the maintainer's call.** You open the PR and wait for the human to merge it — `gh pr merge` is never yours to run.

## Process

1. **Gather the ticket.** Dispatch a **quick** subagent to read it: `gh issue view <n> --json title,body,labels,state`

   **Find its spec, if it has one.** Dispatch a **quick** subagent: `gh issue view <n> --json parent`. A ticket filed by hand may reference an ADR or a design doc instead, or nothing. Read whatever it names — that is the contract the work is measured against. A ticket with no parent is measured against itself, which is fine, and worth saying out loud in the preflight so the user can correct you.

   Read the spec. If any part of the spec is ambiguous, ask the user.

   **Look for prefactoring opportunities.** If you can make the change easier by refactoring adjacent code first, do that refactor in a separate commit. "Make the change easy, then make the easy change." Read the surrounding code to understand the shape of what you're changing.

2. **Preflight.** Dispatch a **quick** subagent:

   ```
   git status --porcelain && git checkout main && git pull
   ```

   Check for existing branches: `gh pr list --head <branch> --state open --json number`
   - If a PR exists, ask: **resume**, **skip**, or **redo**?
   - Branch name: `ticket/<short-kebab-summary>` from ticket title.

3. **Check for parallel work.** Dispatch a **quick** subagent: `gh pr list --state open --json number,title,headRefName,files --limit 20`
   - **No overlap (excluding lockfiles):** safe.
   - **Overlaps a merged-but-unreleased PR or the last 3 merged:** warn and ask the user.
   - **Lockfiles only:** warn — likely merge conflict, not a blocker.

4. **Branch and read code.** Dispatch a **quick** subagent:

   ```
    git fetch origin && git switch -c ticket/<short-kebab-summary> origin/main
   ```

   Dispatch a **quick** subagent to read files at the seams identified in the spec/plan.

5. **Code + test.** Dispatch `/implement` for each implementation unit.

6. **Review.** Dispatch `/code-review`. If a finding is legitimate, dispatch `/implement` to fix it.

7. **PR.** Dispatch a **quick** subagent to fetch the PR template: `ls .github/pull_request_template.md 2>/dev/null && cat .github/pull_request_template.md`. Compose the PR title and body from the template plus the spec. Title format: `<type>(<scope>): <short summary>`. Body must explain what changed and why, for the user. If a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits. No AI attribution.

   Dispatch a **quick** subagent to push and open:

   ```
   git push -u origin <branch> && gh pr create ...
   ```

8. **Gate.** Dispatch a **quick** subagent: `gh pr checks <pr-url> --required`. If any fail, fix the failures yourself, then return here. Do not proceed to human review until all checks pass.

9. **Ask the user** to review.

10. **Review loop.** Read reviewer comments. Dispatch a **quick** subagent to fetch them: `gh pr view <pr-url> --comments`. Address each comment yourself. Return to step 8.

11. **Merged.** Dispatch a **quick** subagent:

    ```
    git checkout main && git pull && git branch -d <branch>
    ```

    Confirm the ticket closed. **Harvest the findings** (below), then report.

12. **Not merged.** Reviewer asked for changes or the ticket was reclassified. Dispatch a **quick** subagent to update labels: `gh issue edit <n> --add-label "status:needs-info"`. Harvest findings, then report.

## Harvest findings

After every merge or reclassify, ask: what did this ticket turn up that the parent spec or earlier tickets didn't predict?

- New naming collisions, undocumented conventions, hidden coupling, inconsistent test patterns.
- Draft or refine `CONTEXT.md` glossary entries for new terms or corrected ones.
- Record any new decisions as ADRs, or propose new tickets for follow-up work the ticket surfaced but didn't resolve.
- If this ticket contradicts the plan or spec, say so.

Harvest what the ticket uncovered into CONTEXT.md or ADRs, even after the ticket is done.

## Completion

Done when: PR merged, ticket closed on tracker, branch deleted, findings harvested into CONTEXT.md or ADRs (or explicitly skipped with reason). Checkable: dispatch a **quick** subagent to verify `gh pr view <pr> --json state` returns `MERGED` and the local branch is deleted.
