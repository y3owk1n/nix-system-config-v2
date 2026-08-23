---
name: implement
description: "Build one unit of a ticket: code, the tests its behaviours actually earn, and an inline review of the diff."
---

# Implement

The coding phase. One or more units. Each unit is: implement → review inline → fix.

## When called from /ship

You receive a brief: goal, files, constraints, done criteria, and the ticket's **behaviours touched**. Work within it. Do not widen the scope because you noticed something adjacent — report it instead.

## When called directly

The argument is what to build. With no argument, list open work: `gh issue list --label type:ticket --state open`. Without a ticket there is no behaviours list, so the test budget falls back to public boundaries in `prd/architecture.md` only.

## Process

### 1. Scope

Decide the goal, the files to read, the tests to run, the constraints. Read only the files at the seams the spec names.

Read `prd/glossary.md` if it exists. It names things, and you are writing the identifiers — a module the glossary calls a Builder should not enter the code as `SystemFactory`.

Independent units run in parallel. A dependent unit waits for what it depends on.

### 2. Implement

Code first. The test comes after the code works, not before.

**The test budget is the ticket's `## Behaviours touched` list.** Nothing else earns a test.

- A behaviour listed there → one test, at the highest seam the spec names, named after the behaviour.
- A public boundary in `prd/architecture.md` — CLI command, exported API, route, persisted schema — where no behaviour is listed but a stranger can invoke it → a test is allowed.
- **Everything else → no test.** A ticket claiming no behaviours ships with no new test file. That is the design, not a gap to fill.

Never write a test that asserts the toolchain works: no install, build, compile, lint, file-exists, or config-parses assertions. They pass forever, fail only when something unrelated breaks, and cost a file each. Never write a test that mirrors implementation — test through public interfaces, mock at system boundaries only.

If you believe something needs a test and no behaviour covers it, **propose a `behaviours.md` entry in your report**. Do not write the test, and do not edit `behaviours.md`.

### 3. Review inline

Read the diff — `git diff` or `git diff --cached` — and apply the review rules already in your context:

- **Standards**: conventions, naming, structure, types, error handling, security. Cite the repo rule, not a general preference.
- **Spec**: does the diff do what the ticket says, and no more. Missing criteria, wrong behaviour, scope creep.

Fix what is legitimate. This is the review — there is no separate dispatch afterwards.

### 4. Report

Return what you built, any deliberate limitation, proposed PRD deltas, and adjacent findings you left alone. File nothing.

## Completion

Done when: every unit's done criteria is met, the diff contains only intended changes, typecheck passes, and the tests that exist pass. Checkable: run the test command and report the exit code.
