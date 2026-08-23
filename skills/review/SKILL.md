---
name: review
description: "Two-axis review of a diff: Standards (repo conventions) and Spec (stated requirements)."
---

# Review

Manual review, outside a ticket. Inside a ticket `/implement` applies the same rules inline — do not dispatch this from `/ship`.

The rubric lives in your context (`## Review`). This skill resolves _what_ to review and handles the case where there is no spec.

## 1. Resolve the change set

| Argument           | Change set                                                                                                 |
| ------------------ | ---------------------------------------------------------------------------------------------------------- |
| none               | `git diff main...` — current branch against main. If the branch _is_ main, `git diff` on the working tree. |
| a PR number or URL | `gh pr diff <n>`                                                                                           |
| a path or glob     | `git diff -- <path>`                                                                                       |
| `--staged`         | `git diff --cached`                                                                                        |

```
git diff <resolved> --stat
cat prd/glossary.md 2>/dev/null || echo "NO_GLOSSARY"
```

Use glossary vocabulary in findings. Say "the Builder", not "the function in lib/default.nix".

## 2. Resolve the spec axis

```
gh pr view <n> --json body 2>/dev/null
```

The PR body links a ticket (`Closes #n`); read that ticket and its parent spec.

**No PR, no ticket, no spec — run Standards only and say so in one line.** Do not go hunting for a plausible spec, and do not infer one from the diff. A spec reconstructed from the code it is meant to judge always passes.

## 3. Standards axis

Conventions, naming, structure, imports, types, error handling, testing patterns, performance, security. Cite the repo rule you are applying — a convention visible elsewhere in the codebase, `CLAUDE.md`, or `prd/decisions.md`. A finding you cannot ground in a repo rule is a preference; drop it.

**Tests get the same rule the code does.** Flag any new test that asserts the toolchain works (install, build, compile, lint, file-exists, config-parses) or mirrors implementation. Flag a test with no behaviour in `prd/behaviours.md` and no public boundary behind it.

## 4. Spec axis

Wrong behaviour, unmet acceptance criteria, API mismatch, unintended side effects, scope creep. Scope creep counts: work the spec did not ask for is a finding even when the code is good.

Check the diff against the non-goals in `prd/product.md` too, if it exists. A change that quietly starts doing something the project decided not to do reads as a feature in review and as a commitment forever after.

## 5. Report

Two lists, each ranked by cost of being wrong. State the bug, show the fix, stop. Skip nits.

```
Standards
  1. <file:line> — <what is wrong> → <the fix>

Spec  (or: skipped — no spec found)
  1. <criterion> — <what is missing>
```

Fix what needs fixing when the user asks. Reviewing and fixing are separate calls.

## Completion

Done when: both axes are run (or Spec is explicitly skipped with the reason), and every finding is either fixed or deferred with a reason. Checkable: re-run the diff and confirm no unfixed finding remains.
