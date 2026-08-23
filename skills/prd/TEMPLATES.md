# PRD file templates

Write only the sections that have content. An empty heading is worse than a missing one.

## product.md

```md
# {Project}

{One sentence: what this is.}

## Problem

{What is broken or missing without this. From the user's side, not the system's.}

## Users

**{Actor}** — {what they do with it, what they do immediately before and after.}

## Why this shape

{Constraints that explain the form: platform, scale, team size, existing systems.}

## Non-goals

{What this deliberately does not do, and why. This is the section that stops scope creep in specs.}
```

## glossary.md

```md
# {Project}

{One or two sentences: what this context is and why it exists.}

## Language

**{Term}**:
{What it IS, in one or two sentences. Not what it does.}
_Avoid_: {rejected synonyms}
```

Rules:

- Be opinionated. Pick the best word; list the alternatives under `_Avoid_`.
- Define what it IS, not what it does.
- Only terms specific to this project. General programming concepts do not belong.
- Group under subheadings when natural clusters emerge.

## decisions.md

Newest first. One decision per `##` block.

```md
# Decisions

## {Short title of the decision}

{1-3 sentences: the context, what was decided, and why.}

**Rejected**: {alternative, and the reason it lost} _(only when worth remembering)_
**Consequences**: {non-obvious downstream effects} _(only when non-obvious)_
```

A decision earns a block only when all three hold: hard to reverse, surprising without context, and the result of a real trade-off. Missing any one, skip it.

Derived decisions carry `_(inferred — unconfirmed)_` until the user confirms.

## architecture.md

```md
# Architecture

## Modules

**{Module}** — {one responsibility}. Interface: {what it exposes}.

## Seams

**{Name}** — {where two modules meet}. Testable because {reason}.

## Boundaries

{What crosses the project edge: CLI commands, exported API, routes, persisted schema. This list is what the test rule calls a public boundary.}
```

## behaviours.md

Human-written. Cap 15. Agents propose, never write.

```md
# Behaviours

What must never break. A test may exist only if it maps to an entry here or to a
public boundary in architecture.md.

1. {Behaviour, stated as an observable outcome — not an implementation.}
2. ...
```

Good: `A rebuild on a host in hosts/default.nix produces a working system.`
Bad: `The mkDarwinSystem function returns an attrset.` (implementation, not promise)

## features/&lt;slug&gt;.md

This file renders to the spec issue. Write it for someone who has not read the conversation.

```md
# {Feature}

## Problem

{The problem the user faces, from the user's perspective.}

## Solution

{The solution, from the user's perspective.}

## User stories

1. As a {actor}, I want {capability}, so that {benefit}.

## Behaviours touched

- #{n} from behaviours.md — {how this feature affects it}

{If none: "None — this feature adds no test." Say it explicitly.}

## Seams

{Where this is tested. Prefer existing seams, highest available, fewest possible.}

## Decisions

{Modules built or modified, interfaces changed, schema changes, API contracts.
No file paths and no code — they go stale within a week.

Exception: a snippet that encodes a decision more precisely than prose can
(state machine, reducer, schema, type shape). Trim to the decision-rich part.}

## Out of scope

{What this feature does not do. Distinguish "not now" from "not ever" — the
first is a follow-up, the second belongs in product.md non-goals.}
```
