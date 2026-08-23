# AI Skills Workflow Guide

How the local agent skills fit together, when to reach for each, and what the workflow deliberately does not do.

## The core loop

```
idea → grill → prd → spec → ship → merged
```

Four skills carry a feature from nothing to merged. Enter at any point: with a PRD already written, start at `spec`; with tickets already cut, start at `ship`.

## The PRD is the source of truth

Everything downstream is rendered from `prd/`, not copied out of it.

```
prd/
├── product.md        ← problem, users, why this exists      (interviewed, never derived)
├── glossary.md       ← domain terms
├── decisions.md      ← decisions and their trade-offs
├── architecture.md   ← modules, seams, public boundaries
├── behaviours.md     ← what must never break                (human-written, cap 15)
└── features/
    └── <slug>.md     ← one per feature; renders to a spec issue
```

**Every file is optional.** A repo with only `glossary.md` is a valid PRD. This repo has exactly that — it is infrastructure, not a product, so it carries no `product.md` and no `behaviours.md`.

The spec issue is **generated** from `features/<slug>.md` and stamped with the file's blob hash in an HTML comment. Never hand-edit a spec issue — edit the feature file, and `/ship` re-renders the issue in place on its next run. Tickets are the opposite: authored, transient, unstamped, closed on merge, never regenerated.

## The test rule

Test sprawl is a budget problem, so the workflow gives it a budget.

A test may exist only if it maps to **a numbered entry in `prd/behaviours.md`** or **a public boundary in `prd/architecture.md`** — a CLI command, exported API, route, or persisted schema. Everything else gets no test.

Banned outright, at every layer:

- assertions that the toolchain works — install, build, compile, lint, file-exists, config-parses
- tests that mirror implementation rather than exercising a public interface

`behaviours.md` is capped at **15 entries and is never written by an agent.** Agents propose entries in a PR body or report; you add them. At the cap, the agent stops and asks which entry comes out. The cap is what makes the list something you can hold in your head when deciding whether something needs a test — an uncapped list is a wishlist, and the sprawl comes back.

A ticket that touches no behaviour ships with no new test file. That is the design, and every skill states it explicitly rather than leaving it implicit.

## Skills by phase

### Shape

| Skill   | What it does                                                                                          | When                                                        |
| ------- | ----------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| `grill` | Structured Q&A: asks, recommends, you pick. Emits a PRD delta at the end but applies nothing unasked. | A rough idea you want stress-tested before writing it down. |

### Define

| Skill  | What it does                                                                                                                                              | When                                                                         |
| ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `prd`  | Creates, derives, or updates the PRD. Four modes: `derive` (existing project), `create` (new), `feature` (add a feature file), `update` (record a delta). | Starting a project, adding a feature, or recording what a ticket taught you. |
| `spec` | Renders a feature file to a spec issue **and** cuts its ticket sub-issues in one pass.                                                                    | You have a feature file and want implementable work.                         |

`derive` splits its sources deliberately: glossary, architecture, and decisions are read out of the code; `product.md` and `behaviours.md` are interviewed and never derived. Why a project exists and what must never break are not in the code, and a derived version is fiction with a confident tone. Derived decisions carry `_(inferred — unconfirmed)_` until you confirm them.

### Ship

| Skill       | What it does                                                                                         | When                                                              |
| ----------- | ---------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `ship`      | Spec mode loops every ticket under a spec; ticket mode ships one. Drift-checks the spec stamp first. | You want a feature, or one ticket, landed.                        |
| `implement` | Codes one unit and reviews its own diff inline. No branch, no PR.                                    | Called by `ship`. Directly, when you just want code from a brief. |
| `review`    | Two-axis review of any diff: Standards and Spec.                                                     | Manually, outside a ticket. `ship` does not dispatch it.          |
| `pr`        | Commits and opens a PR.                                                                              | Ad-hoc work outside the ticket flow.                              |

### Maintain

| Skill                           | What it does                                                                                                                                                |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `triage`                        | Categorise, assess readiness, assign labels, write agent-ready briefs. The entry point for work that does not come from a PRD — inbound bugs, external PRs. |
| `diagnose`                      | Reproduce, minimise, hypothesise, test, fix, verify.                                                                                                        |
| `research`                      | Investigate a question against primary sources.                                                                                                             |
| `improve-codebase-architecture` | Scan for shallow-to-deep refactors. HTML or Markdown report with before/after diagrams.                                                                     |

### Extend

| Skill                | What it does                                                                                                                                                                                             |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `writing-for-agents` | How to write and prune what agents read: SKILL.md, CLAUDE.md, prd/ files. Ships `CHECKS.md` — seven checks catching broken pointers, orphaned reference files, and an enable list out of step with disk. |
| `add-skill`          | Add a skill source or local skill to the Nix config.                                                                                                                                                     |
| `find-skills`        | Discover skills from the open ecosystem.                                                                                                                                                                 |

## Dispatch chains

```
ship
  └── implement          (review happens inside implement, inline)

prd
  └── grill    (for product.md and behaviours.md)

improve-codebase-architecture
  └── grill
```

## What the loop deliberately does not do

Each of these was a step that existed and was cut. They are listed so a future reader knows the omission is a decision, not an oversight.

- **No separate `/review` dispatch inside `ship`.** The rubric lives in the nix-managed context (`## Review` in `common-ai.nix`), so `implement` applies it without a second context hydration. `review` survives as a manual entry point.
- **No clash test.** Scanning `gh pr list --files` for overlapping work guards a multi-developer repo. Bring it back when that changes.
- **No per-unit diff review in `implement` followed by a review pass in `ship`.** That was the same read, twice.
- **No harvest ritual.** PRD deltas land in the ticket's own PR, in a `docs(prd):` commit, rather than as a follow-up nobody writes.
- **No `.scratch/` and no local-markdown tracker.** `prd/features/<slug>.md` is already the offline artefact; a second copy under `.scratch/` was the drift the PRD exists to remove.
- **No ADRs.** `prd/decisions.md` replaces `docs/adr/`, with the same three-part test: hard to reverse, surprising without context, a real trade-off. Missing any one, it does not get recorded.

## Quick reference

| I want to...                         | Run                             |
| ------------------------------------ | ------------------------------- |
| Stress-test an idea                  | `grill`                         |
| Set up a PRD for an existing project | `prd` (derive)                  |
| Set up a PRD for a new project       | `prd` (create)                  |
| Add a feature to the PRD             | `prd` (feature)                 |
| Cut a spec and its tickets           | `spec`                          |
| Ship a whole feature                 | `ship`                          |
| Ship one ticket                      | `ship <ticket>`                 |
| Write code from a brief              | `implement`                     |
| Review a diff manually               | `review`                        |
| Open a PR outside the flow           | `pr`                            |
| Triage inbound issues                | `triage`                        |
| Debug a hard bug                     | `diagnose`                      |
| Research a question                  | `research`                      |
| Audit architecture                   | `improve-codebase-architecture` |
| Write or prune a skill               | `writing-for-agents`            |
| Install a skill                      | `add-skill`                     |
| Find a skill                         | `find-skills`                   |

## Labels

Colon format: `type:bug`, `status:ready-for-agent`, `priority:critical`, `scope:backend`.

Single-sourced in `skills/triage/LABELS.md`. `triage` assigns them, `spec` inherits `priority:*` and `scope:*` onto every ticket it cuts, and `ship` moves `status:*` as tickets start, block, and merge.
