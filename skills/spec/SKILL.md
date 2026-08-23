---
name: spec
description: "Render a PRD feature file to a spec issue and cut its ticket sub-issues in one pass."
disable-model-invocation: true
---

# Spec

One pass: `prd/features/<slug>.md` → a spec issue → its ticket sub-issues.

The spec issue is **generated** from the feature file and stamped with its hash. Never hand-edit a spec issue — edit the feature file and let `/ship` regenerate it. Tickets are **authored**, transient, and die on merge; they carry no stamp and are never regenerated.

GitHub is the tracker. There is no local-markdown mode — `prd/features/<slug>.md` already is the offline artefact.

## Process

### 1. Resolve the feature file

Argument may be a slug, a path, or nothing.

```
gh auth status && git remote get-url origin
ls prd/features/ 2>/dev/null || echo "NO_FEATURES"
```

No feature file? Stop and dispatch `/prd` in **feature** mode. This skill renders; it does not invent.

### 2. Read the PRD

```
cat prd/product.md prd/glossary.md prd/behaviours.md prd/architecture.md 2>/dev/null
cat prd/features/<slug>.md
```

Use glossary vocabulary exactly, in the spec and in every ticket title.

Two things can stop publication and both are cheaper to catch here than in review:

- The feature contradicts an entry in `prd/decisions.md`.
- The feature reaches into a **non-goal** in `prd/product.md`.

Either one, stop and say so rather than publishing and letting it surface as scope creep in a PR.

### 3. Gate on behaviours

If `prd/behaviours.md` does not exist or is empty, **stop**. Tickets cannot be cut until at least one behaviour is named. Send the user to `/prd`.

This gate is why the workflow produces few tests instead of many. Do not route around it.

### 4. Publish the spec issue

Render the feature file to the issue body with `SPEC-RENDER.md`. Append the provenance stamp as the last line:

```
<!-- prd-source: prd/features/<slug>.md@<blob-sha> -->
```

Get the hash from `git hash-object prd/features/<slug>.md`. It changes when and only when the file changes, which is what makes the drift check in `/ship` exact.

```
gh issue create \
  --label "type:spec,status:ready-for-agent,<priority>,<scope>" \
  --title "Spec: <feature>" \
  --body "<rendered body>"
```

Labels come from `triage/LABELS.md`.

### 5. Cut the tickets

Break the feature into **tracer bullets**: narrow but complete paths through every layer, each demoable on its own, each sized for one fresh context window.

- Vertical, never a horizontal slice of one layer.
- Prefactors first. "Make the change easy, then make the easy change."
- Declare **blocking edges**: which tickets must land first. No blockers means it can start now.
- **Wide refactors** break the vertical rule. Use expand-contract sequencing — see `WIDE-REFACTORS.md`.

Assign each ticket the behaviours it touches, by number, from the feature file. A ticket touching none gets no test — that is allowed and must be stated on the ticket, not left implicit.

### 6. Quiz the user, once

Present the breakdown as a numbered list: title, blocked by, what it delivers, behaviours touched, labels.

Ask:

- Is the granularity right?
- Are the blocking edges real, or just an ordering preference?
- Any ticket claiming zero behaviours that should claim one?

Iterate until approved. This is the only human stop in this skill — make it count rather than splitting it across two.

### 7. Publish the tickets

In dependency order, blockers first, as sub-issues of the spec:

```
gh issue create \
  --parent <spec-number> \
  --label "type:ticket,status:ready-for-agent,<priority>,<scope>" \
  --title "<NN>: <title>" \
  --body "<ticket body>"
```

A ticket blocked by another in this batch starts at `status:blocked`. `/ship` promotes it when its blockers merge. Carry `--milestone` from the spec if it has one.

Ticket body:

```md
## What to build

The end-to-end behaviour this makes work, from the user's side. Not a layer-by-layer list.

## Parent

#<spec-number>

## Behaviours touched

- #<n> from prd/behaviours.md

or: None — this ticket adds no test.

## Blocked by

#<n>, or "None (can start immediately)".

## Acceptance criteria

- [ ] ...
```

## Completion

Done when: the spec issue exists with a provenance stamp, every ticket is a sub-issue with correct labels and blocking edges, each ticket names its behaviours or explicitly claims none, and the user approved the breakdown. Checkable: `gh issue view <spec> --json subIssues` lists every ticket.
