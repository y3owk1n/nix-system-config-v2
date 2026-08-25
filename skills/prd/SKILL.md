---
name: prd
description: "Create, derive, or update the PRD — the single source of truth every other skill reads."
disable-model-invocation: true
---

# PRD

The PRD replaces `CONTEXT.md`, `docs/adr/`, and the spec body. It is the one durable layer. Specs and tickets are rendered from it; they are not a second copy of it.

## Structure

```
prd/
├── product.md        ← problem, users, why this exists
├── glossary.md       ← domain terms (was CONTEXT.md)
├── decisions.md      ← decisions and their trade-offs (was docs/adr/)
├── architecture.md   ← modules, seams, boundaries
├── behaviours.md     ← what must never break — the test budget
└── features/
    └── <slug>.md     ← one per feature; renders to a spec issue
```

**Every file is optional.** A repo with only `glossary.md` is a valid PRD. Never fabricate a file to complete the set, and never block on a missing one — read what exists, say what is missing, move on.

Templates for each file: `TEMPLATES.md`, in this skill's own directory next to this `SKILL.md` — not `prd/` in the target repo.

## Modes

Pick from the argument, or ask.

| Mode        | When                                                    |
| ----------- | ------------------------------------------------------- |
| **derive**  | Existing project, no PRD yet                            |
| **create**  | New project, no code yet                                |
| **feature** | Add `features/<slug>.md` to an existing PRD             |
| **update**  | Record a delta — new term, new decision, corrected fact |

## derive — existing project

Two halves, and they are not interchangeable.

**Derived from code** — glossary, architecture, decisions. These are recoverable. Read the repo and draft them:

```
git log --oneline -40
ls -R --ignore=node_modules --ignore=.git . | head -100
```

Walk the hot spots the log points at. For decisions, look for the choice that a reader would question: a non-obvious dependency, a hand-rolled thing where a library exists, a boundary drawn somewhere odd. Record what was chosen and why it plausibly was — then **mark every derived decision `status: inferred`** until the user confirms it. An inferred decision presented as fact is the worst artefact this skill can produce.

**Interviewed, never derived** — `product.md` and `behaviours.md`. Why the project exists, who it serves, and what must never break are not in the code. A derived version of these is fiction with a confident tone. Dispatch `/grill` for them, or ask directly:

- What breaks for someone if this stops existing?
- Who runs this, and what do they do immediately before and after?
- Name the things that must never break. Stop at 15.

Write nothing to `product.md` or `behaviours.md` without an answer.

## create — new project

Interview first, code second. Run `/grill`, then write `product.md`, `glossary.md`, and `behaviours.md` from its output. `architecture.md` and `decisions.md` start empty and grow.

**`behaviours.md` must have at least one entry before `/spec` will cut tickets.** That gate is the point: it forces you to name what must never break while it is still cheap to change your mind.

## feature — add a feature file

1. Read `product.md`, `glossary.md`, `behaviours.md`, `architecture.md` — whichever exist.
2. Draft `prd/features/<slug>.md` from this skill's `TEMPLATES.md`. Use glossary vocabulary exactly; if the feature needs a term the glossary lacks, add the term first.
3. **Sketch the seams.** Where will this be tested? Prefer existing seams. Use the highest seam available. Fewer is better; one is ideal. Name them in the feature file and confirm them with the user.
4. Map the feature to `behaviours.md`. Each behaviour it touches gets referenced by number. A feature touching no listed behaviour gets no tests — say so out loud so the user can add a behaviour if that is wrong.

Then hand off: `/spec` renders this file to an issue and cuts its tickets.

## update — record a delta

Called at the end of a ticket, or directly. Apply only what the change actually established:

- **New or sharpened term** → `glossary.md`
- **A choice that was hard to reverse, surprising, and a real trade-off** → `decisions.md`. If any of the three is missing, do not record it.
- **Module boundary moved** → `architecture.md`
- **Feature scope changed** → `features/<slug>.md` (this invalidates the published spec issue; `/ship` regenerates it)

Commit PRD edits separately from code, as `docs(prd): <what>`, so a reviewer can read them on their own.

## behaviours.md is yours

**Never write to `behaviours.md`.** Propose entries — in the PR body, in a report, in conversation — and let the user add them.

**Cap: 15.** It is read into context on every ticket, and its job is to be a list a human can hold in their head when deciding whether something needs a test. At the cap, stop and ask which entry comes out. Do not append.

The cap is per project, not per feature.

## Completion

Done when: every file the mode calls for exists and is non-empty, `product.md` and `behaviours.md` contain only interviewed content, every derived decision is marked `inferred` or confirmed, and the user has seen the file list. Checkable: `ls prd/` and `wc -l prd/*.md` show the expected files with content.
