---
name: create-pr
description: "Commits changes and opens a pull request. Use when asked to commit, create a PR, open a pull request, or ship finished work."
---

# Create PR

## Guardrails

- **No AI attribution.** Never mention Claude, Anthropic, or AI in commits, PR title, body, or branch name.
- **Never push to `main`.** New branch always.
- **Explicit staging only.** No `git add -A` or `git add .` — stage paths individually.
- **One change per commit, one change per PR.**

## Steps

1. **Branch.** `git switch -c <type>/<short-kebab-summary>` off `main`.
2. **Verify.** Run CI checks (`just ci`, `make test`, `npm test`). Never open on red.
3. **Stage selectively.** `git add <paths>` for this change only. Check `git status --short`.
4. **Commit.** Format: `<type>(<scope>): <subject>` — imperative, lowercase, no period.
5. **Check for template.** `ls .github/pull_request_template.md` and common locations. Use it if found.
6. **Write PR body.** See template below. Open with `This PR <verb> ...`.
7. **Grep for leaks.** Search commits and body for `claude`, `anthropic`, `co-authored`, `generated with`. Any hit is a bug.
8. **Push and open.** `git push -u origin <branch>` then `gh pr create`.
9. **Watch CI.** `gh pr checks --watch`. Fix failures yourself.

## Commit format

`<type>(<scope>): <subject>`

Types: `feat`, `fix`, `perf`, `revert`, `docs`, `refactor`, `test`, `chore`, `ci`, `build`, `style`.

Write the subject for a **user**, not the diff:

- `fix(auth): handle expired tokens gracefully` ✓
- `fix: update auth.go` ✗

Body: explain _why_ and behaviour change, wrap at 72 chars. `Closes #123` when fixing an issue.

## PR body (no template)

```
This PR <verb> ...

## What changed

<2-3 sentences: user-visible behaviour>

## Why

<1-2 sentences: motivation>

## How to test

<concrete steps>
```

Write for the **reader**, not the diff:

- `This PR fixes button responsiveness on touch devices.` ✓
- `Updates handleClick in Button.tsx` ✗

Config/command changes: name them exactly as typed, note defaults, say whether existing configs keep working.
