# AI Skills Workflow Guide

A reference for how the local agent skills fit together, when to reach for each one, and how the dispatch chain works.

## The core loop

```
.idea → grill-interview → to-spec → to-tickets → ship-spec → ship-ticket → create-pr
         (or grill-with-docs)
```

Every feature follows this path. You can enter at any point — if you already have a spec, skip to `to-tickets`.

## Skills by phase

### 1. Shape the idea

| Skill             | What it does                                                                                          | When to use                                                                    |
| ----------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `grill-interview` | Structured Q&A to sharpen a plan. Asks questions, recommends options, you pick. No artefacts created. | You have a rough idea and want to stress-test it before writing anything down. |
| `grill-with-docs` | Same interview, but records decisions as ADRs and updates the glossary (CONTEXT.md) as it goes.       | You want the interview to leave a paper trail.                                 |

### 2. Write the spec

| Skill          | What it does                                                                            | When to use                                                                    |
| -------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `to-spec`      | Synthesises the conversation into a spec and publishes it (GitHub issue or local file). | You've finished grilling and want a formal spec.                               |
| `init-project` | Sets up CONTEXT.md, docs/adr/, .scratch/ — the scaffolding other skills expect.         | First time using the workflow on a new project. Run this before anything else. |

### 3. Break into tickets

| Skill        | What it does                                                                                                 | When to use                                        |
| ------------ | ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------- |
| `to-tickets` | Breaks a spec into tracer-bullet tickets with blocking edges. Publishes as GitHub sub-issues or local files. | You have a spec and want implementable work units. |

### 4. Ship

| Skill         | What it does                                                                                          | When to use                                      |
| ------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| `ship-spec`   | Iterates through every ticket in a spec, dispatching `ship-ticket` for each, until the feature ships. | You want the whole spec landed in one go.        |
| `ship-ticket` | Ships one ticket: branches, codes, reviews, opens PR, waits for merge.                                | You want one ticket landed.                      |
| `implement`   | Codes the implementation from a brief. No branching, no PR — just code and tests.                     | Called by `ship-ticket` during the coding phase. |
| `code-review` | Two-axis review: Standards (repo conventions) and Spec (issue requirements).                          | Called by `ship-ticket` after coding.            |
| `create-pr`   | Commits changes and opens a pull request.                                                             | You've finished coding and want a PR.            |

### 5. Maintain

| Skill             | What it does                                                                            | When to use                                         |
| ----------------- | --------------------------------------------------------------------------------------- | --------------------------------------------------- |
| `triage`          | Moves issues through triage: categorise, assess readiness, assign labels, write briefs. | You have a pile of issues to organise.              |
| `diagnosing-bugs` | Structured debugging loop: reproduce, minimise, hypothesise, test, fix, verify.         | You have a hard bug and need a systematic approach. |
| `research`        | Investigates a question against primary sources, captures findings as Markdown.         | You need facts gathered from docs, APIs, or repos.  |

### 6. Extend

| Skill         | What it does                                                  | When to use                                          |
| ------------- | ------------------------------------------------------------- | ---------------------------------------------------- |
| `add-skill`   | Adds a skill source or local skill to the Nix configuration.  | You want to install a new skill.                     |
| `find-skills` | Discovers skills from the open ecosystem (skills.sh, GitHub). | You're looking for a skill that might already exist. |

### 7. Architecture

| Skill                           | What it does                                                                                                                | When to use                                       |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| `improve-codebase-architecture` | Scans for deepening opportunities (shallow → deep modules). Produces an HTML or Markdown report with before/after diagrams. | You want an architectural audit of your codebase. |

## Dispatch chains

Some skills automatically call other skills. You don't need to orchestrate these — just invoke the top-level one.

```
ship-spec
  └── ship-ticket
        ├── implement
        └── code-review

grill-with-docs
  └── grill-interview

improve-codebase-architecture
  └── grill-interview
```

## Quick reference

| I want to...                     | Run this                        |
| -------------------------------- | ------------------------------- |
| Set up a new project             | `init-project`                  |
| Stress-test an idea              | `grill-interview`               |
| Stress-test and record decisions | `grill-with-docs`               |
| Write a spec from a conversation | `to-spec`                       |
| Break a spec into tickets        | `to-tickets`                    |
| Ship a whole feature             | `ship-spec`                     |
| Ship one ticket                  | `ship-ticket`                   |
| Just write code from a brief     | `implement`                     |
| Review a changeset               | `code-review`                   |
| Open a PR                        | `create-pr`                     |
| Triage issues                    | `triage`                        |
| Debug a hard bug                 | `diagnosing-bugs`               |
| Research a question              | `research`                      |
| Audit codebase architecture      | `improve-codebase-architecture` |
| Install a skill                  | `add-skill`                     |
| Find a skill                     | `find-skills`                   |

## File structure

The workflow creates and reads from these files:

```
/
├── CONTEXT.md              ← domain glossary (single source of truth for terms)
├── CONTEXT-MAP.md          ← only if multi-context repo
├── docs/
│   └── adr/                ← architecture decision records (0001-slug.md, etc.)
└── .scratch/               ← local specs, tickets, reviews (gitignored)
```

`init-project` creates these for you. Other skills read and update them as work progresses.

## Labels

All labels use colon format: `type:bug`, `status:ready-for-agent`, `priority:critical`, `scope:backend`.

Labels are single-sourced in the `triage` skill. When creating specs or tickets, the skills apply labels automatically.
