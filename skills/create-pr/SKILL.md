---
name: create-pr
description: "Commit changes and open a pull request."
---

# Create PR

## Guardrails

- **No AI attribution.** Never mention Claude, Anthropic, or AI in commits, PR title, body, or branch name.
- **Never push to `main`.** New branch always.
- **Explicit staging only.** No `git add -A` or `git add .` — stage paths individually.
- **One change per commit, one change per PR.**

## Steps

1. **Branch.** If already on a feature branch (not `main`), skip this step. Otherwise dispatch a **quick** subagent: `git switch -c <type>/<short-kebab-summary>`
2. **Verify.** Dispatch a **quick** subagent to run CI checks (`just ci`, `make test`, `npm test`). Only open when CI is green. Skip if already verified (e.g. called from `/ship-ticket` which ran fast checks).
3. **Stage selectively.** Dispatch a **quick** subagent: `git add <paths> && git status --short`
4. **Commit.** Compose the commit message (format: `<type>(<scope>): <subject>`, imperative, lowercase, no period). Dispatch a **quick** subagent to grep the message for AI attribution leaks (`claude|anthropic|co-authored|generated with`) and commit.
5. **Check for template.** Dispatch a **quick** subagent: `ls .github/pull_request_template.md 2>/dev/null && cat .github/pull_request_template.md`
6. **Write PR body.** Compose the body using the template below. Open with `This PR <verb> ...`.
7. **Push and open.** Dispatch a **quick** subagent: `git push -u origin <branch> && gh pr create --title "<title>" --body "<body>"`
8. **Watch CI.** Dispatch a **quick** subagent: `gh pr checks --watch`

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

Done when: CI is green, PR is open with title and body, no AI attribution leaks. Checkable: dispatch a **quick** subagent to verify `gh pr checks` passes and `gh pr view` shows the expected title/body.
