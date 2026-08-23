---
name: to-tickets
description: "Break a plan, spec, or conversation into tracer-bullet tickets with declared blocking edges."
disable-model-invocation: true
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets**: tracer-bullet vertical slices, each declaring the tickets that **block** it.

## Labels

Apply `type:ticket`, one `status:*`, plus one `priority:*` and one `scope:*` from the vocabulary in `triage` SKILL.md. Inherit priority and scope from the parent spec if one exists.

## Process

### 1. Resolve the tracker

Dispatch a **quick** subagent: `gh auth status && git remote get-url origin`

- If it succeeds, use GitHub.
- Otherwise, ask the user: **GitHub** (creates issues via `gh`) or **local markdown** (writes to `.scratch/`)?

Remember the choice for this session.

### 2. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path, an issue number or URL) as an argument, dispatch a **quick** subagent to fetch it: `gh issue view <n> --json title,body,labels,milestone`

### 3. Explore the codebase (optional)

If you have not already explored the codebase, dispatch a **quick** subagent to gather context:

```
cat CONTEXT.md 2>/dev/null || echo "NO_CONTEXT"
ls docs/adr/ 2>/dev/null || echo "NO_ADRS"
```

Use the glossary vocabulary in ticket titles and descriptions. Respect any ADRs returned.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 4. Draft vertical slices

Break the work into **tracer bullet** tickets. Decide: title, blocking edges, what it delivers, labels.

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests): vertical, NOT a horizontal slice of one layer.
- A completed slice is demoable or verifiable on its own.
- Each slice is sized to fit in a single fresh context window.
- Any prefactoring should be done first.

Give each ticket its **blocking edges**: the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

**Wide refactors** (one mechanical change across the whole codebase) break the vertical-slicing rule. For those, use expand-contract sequencing. See `to-tickets/WIDE-REFACTORS.md` for the full pattern.

### 5. Quiz the user

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work
- **Labels**: type:ticket, status:ready-for-agent, priority:_, scope:_

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct: does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?
- Are the labels correct?

Iterate until the user approves the breakdown.

### 6. Publish the tickets

How depends on the tracker chosen in step 1.

**GitHub** — publish one issue per ticket as a **sub-issue** of the parent spec, in dependency order (blockers first).

1. Resolve the parent issue number from the reference passed in step 2.
2. For each ticket, compose the ticket body using the template below. Then dispatch a **quick** subagent to publish:
   ```
   gh issue create \
     --parent <parent-number> \
      --label "type:ticket,status:ready-for-agent,<priority>,<scope>" \
     --title "<NN>: <Ticket title>" \
      --body "<ticket body>"
   ```
   Record the issue number from quick's output so subsequent tickets can reference it.

Use `--milestone` if the parent spec has one.

If a ticket is blocked by another ticket in this batch, set its initial status to `status:blocked` instead of `status:ready-for-agent`. Update to `status:ready-for-agent` once its blockers are merged.

**Local** — compose the ticket content, then dispatch a **quick** subagent to write the file under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`.

## Ticket Template

### GitHub (issue body)

```
## What to build

The end-to-end behaviour this ticket makes work, from the user's perspective, not layer-by-layer implementation.

## Parent

#<parent-issue-number>

## Blocked by

- A reference to each blocking ticket (e.g. #3), or "None (can start immediately)".

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
```

### Local (file)

```
# <NN>: <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work, from the user's perspective, not a layer-by-layer implementation list.

**Blocked by:** the numbers/titles of the tickets that gate this one, or "None (can start immediately)".

**Status:** ready-for-agent

**Labels:** type:ticket, priority:<level>, scope:<area>

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
```

## Completion

Done when: every ticket is published with correct labels, blocking edges declared, parent linked, and the user has approved the breakdown. Checkable: dispatch a **quick** subagent to verify `gh issue list --label type:ticket --state open` shows all expected tickets with correct parent linkage.
