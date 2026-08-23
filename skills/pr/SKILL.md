---
name: pr
description: "Commit changes and open a pull request."
---

# PR

## Guardrails

- **No AI attribution.** Never mention Claude, Anthropic, or AI in commits, PR title, body, or branch name.
- **Never push to `main`.** New branch always.
- **Explicit staging only.** No `git add -A` or `git add .` — stage paths individually.
- **One change per commit, one change per PR.**

## Steps

1. **Branch.** Already on a feature branch: skip. Otherwise `git switch -c <type>/<short-kebab-summary>`.
2. **Verify.** Run the repo's checks (`just ci`, `make test`, `npm test`). Open only on green. Skip when `/ship` already ran the fast checks.
3. **Stage selectively.** `git add <paths> && git status --short` — named paths only.
4. **Commit.** Compose the message, then grep it for attribution leaks (`claude|anthropic|co-authored|generated with`) before committing.
5. **Check for a template.** `cat .github/pull_request_template.md 2>/dev/null`
6. **Write PR body.** Compose the body using the template below. Open with `This PR <verb> ...`.
7. **Push and open.** `git push -u origin <branch> && gh pr create --title "<title>" --body "<body>"`
8. **Watch CI.** `gh pr checks --watch`

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

## Completion

Done when: checks are green, the PR is open with a title and body written for a reader, and no commit or PR text mentions Claude, Anthropic, or AI. Checkable: `gh pr checks` passes, and `gh pr view --json title,body` piped through `grep -iE 'claude|anthropic|co-authored|generated with'` returns nothing.
