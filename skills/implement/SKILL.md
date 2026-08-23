---
name: implement
description: "Execute a spec or ticket: code, tests, refactors."
disable-model-invocation: true
---

# Implement

The coding phase. One or more implementation units. Each unit is: implement → review diff → fix findings.

## When called directly

The argument is a short description of what to build. If no argument is provided, dispatch a **quick** subagent to read `CONTEXT.md` for available work items.

## When called from another skill

Receives a brief with: goal, files, constraints, done criteria. Work within the received brief only.

## Process

### 1. Scope

Decide: goal, files to read, tests to run, constraints. Dispatch a **quick** subagent to read the files at the seams identified in the spec/plan.

If the work breaks into independent units, implement them in parallel. If a unit depends on another, implement the dependency first.

### 2. Implement

For each unit:

- **Goal**: what you should achieve
- **Files**: exact files to read and modify
- **Constraints**: what you must or must not do
- **Done criteria**: how to verify the work is complete

Implement the code and write tests using the TDD discipline from your context.

### 3. Review

Dispatch a **quick** subagent to read the diff: `git diff --cached` or `git diff`. Report findings. If legitimate, fix them.

## Completion

Done when: every unit's done criteria is met, the diff is clean (`git diff` shows only intended changes), typecheck passes, and affected tests pass. Checkable: dispatch a **quick** subagent to run the test command and report exit code.
