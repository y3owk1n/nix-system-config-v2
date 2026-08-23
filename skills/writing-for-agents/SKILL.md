---
name: writing-for-agents
description: "Write and prune documents agents read: SKILL.md, CLAUDE.md, AGENTS.md, prd/ files."
---

# Writing for Agents

A document an agent reads is a budget, not a manuscript. Every line either changes what the agent does or costs tokens for nothing.

## The two loads

**Context load** — material present every turn: `CLAUDE.md` lines, and every skill's `description`. Charged whether or not it is used. Minimise it.

**Cognitive load** — what a human must remember exists. Paid by you, not the model. It is the price of your own agency; do not optimise it to zero by inlining everything.

A pointer trades context load for cognitive load. Material with no pointer relies on you remembering it.

## The description is the pointer

A skill's `description` is loaded on every turn of every session. It is the highest-leverage sentence in the file and the only part most sessions ever read.

Write it as **what it does + when to reach for it**. Front-load the trigger word.

- `"Ship a spec or a single ticket from start to merged PR."` — the work is named first
- `"A helpful skill for various shipping-related tasks."` — no trigger, no branch, pure cost

One trigger per real branch. Collapse synonyms rather than listing them.

`disable-model-invocation: true` when the skill should only run when you type it. Use it for anything that publishes, mutates a tracker, or restructures files — `prd`, `spec`, `grill`, `triage`. Leave it off for skills the model should reach for on its own — `ship`, `implement`, `review`.

## Information hierarchy

Three tiers, by immediacy:

1. **Step** — an ordered action the agent takes. The primary tier.
2. **In-file reference** — a flat peer-set consulted on demand: a rubric, a label table, a template.
3. **Disclosed reference** — a sibling file reached by a pointer. Loads only when the pointer fires.

Promote to a sibling file when a section is consulted rather than followed, and is long enough to thin attention around it. `ship/TRACKERS.md`, `triage/LABELS.md`, `spec/SPEC-RENDER.md`, and `prd/TEMPLATES.md` are all this. Point at them by filename in backticks — bare from the skill's own directory, path-qualified when pointing across skills.

Co-locate: a concept's definition, its rules, and its caveats live under one heading. Splitting them across sections costs a lookup every time.

## Completion criteria

Every skill ends on a `## Completion` section, and it does real work:

- **Checkable** — name the command that proves it. "Done when it works" invites the agent to declare victory early.
- **Demanding** — "every ticket is a sub-issue with correct labels and blocking edges" forces legwork that "tickets are published" does not.

Split a sequence into separate steps only when a later step's visibility tempts the agent to stop short of the earlier one.

## Leading words

A leading word recruits a prior the model already holds, so it changes behaviour in one token instead of a paragraph. `tracer bullet`, `seam`, `prefactor`, `expand-contract`, `frontier` each replace a paragraph of explanation.

Prefer them to restatement. When you catch yourself explaining the same behaviour twice in different words, there is a leading word for it.

**Negation is the failure mode.** Prohibiting a behaviour drags it into context. `Never guess the slug from the issue title` works only because it is immediately followed by what to do instead. A bare prohibition is worse than nothing — state the positive target.

## Pruning

Cut, in this order:

1. **No-ops** — instructions the model already follows by default. "Write clean code", "be careful", "use good judgment". Pure cost.
2. **Duplication** — each meaning gets one source of truth. Two copies drift, and the duplicate inflates the idea's apparent importance.
3. **What the environment already says** — file layout, script names, config values. The agent can look. Document only what looking will not reveal.
4. **Stale specifics** — file paths and code snippets go out of date within a week. Name the module, not the line.

Shorter documents stay correct longer. A document that grows every time something surprises you becomes a document nobody reads.

## This repo's conventions

```
skills/<name>/
├── SKILL.md          ← frontmatter + steps
└── REFERENCE.md      ← SCREAMING-KEBAB, one concern per file
```

- Frontmatter `name:` must equal the directory name. The build fails otherwise.
- Every skill in `skills/` must appear in `skills.enable` in `modules/home/packages/skills.nix`, and nothing may appear there that is not on disk. The nix allowlist is validated at eval.
- Cross-skill references use the backticked flat form: `/ship`, `/implement`. An external skill is `/<idPrefix>_<skill>` — `/cursor-team-kit_deslop`, never a slash path.
- Reference the PRD by its real files: `prd/glossary.md`, `prd/behaviours.md`, `prd/architecture.md`, `prd/decisions.md`, `prd/product.md`, `prd/features/<slug>.md`. Treat every one as optional — read what exists, say what is missing, continue.
- `AI_NOTES.md` documents the workflow as a whole. A new skill, a rename, or a cut belongs there too, or it is invisible.

Installing a skill — flake input, source, enable list — is `/add-skill`. This skill is only about what goes inside the file.

## Verify

Run the checks in `CHECKS.md`. They catch the failures that are invisible on reading: a pointer to a file that does not exist, a name that does not match its directory, an enable list out of step with disk.

## Completion

Done when: the description names its trigger, every pointer resolves, no section duplicates another, `## Completion` is checkable, and every check in `CHECKS.md` prints nothing. Checkable: run all seven checks and confirm zero findings.
