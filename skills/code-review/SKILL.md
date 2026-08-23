---
name: code-review
description: "Two-axis review: Standards (repo conventions) and Spec (issue requirements)."
---

# Code Review

## Process

### 1. Capture the change set

Dispatch a **quick** subagent to read the codebase context:

```
git diff main... --name-only
cat CONTEXT.md 2>/dev/null || echo "NO_CONTEXT"
```

### 2. Locate the spec

Dispatch a **quick** subagent to identify the originating issue or spec:

```
gh pr view <pr-number> --json body
```

### 3. Run Standards review

Evaluate against the repo's coding standards:

Standards review catches: conventions, patterns, naming, structure, imports, types, error handling, testing patterns, performance concerns, security issues.

### 4. Run Spec review

Evaluate the spec match yourself:

Spec review catches: wrong behaviour, incomplete acceptance criteria, missing test scenarios, API mismatches, side effects, undocumented changes, scope creep.

### 5. Report

Present the two reviews side by side:

- **Standards**: ...
- **Spec**: ...

Fix what needs fixing.

## Completion

Done when: both Standards and Spec reviews are complete, every finding is either fixed or explicitly deferred with reason, and the fix is verified by re-running the review. Checkable: dispatch a **quick** subagent to re-run `git diff` and confirm no unfixed findings remain.
