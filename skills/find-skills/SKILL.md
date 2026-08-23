---
name: find-skills
description: "Search the open skills ecosystem for a skill that already does what the user is about to build."
---

# Find Skills

Discovery only. **Installation in this repo is declarative — `/add-skill` writes the flake input and the enable list.**

`npx skills add -g` writes into `~/.claude/skills`, which nix owns and regenerates. An install done that way disappears on the next `just rebuild`. Use it to inspect a candidate, never to keep one.

## Process

### 1. Name the domain and the task

"React performance" finds things; "make it faster" does not. If the request is vague, sharpen it before searching — one specific query beats three broad ones.

### 2. Check the leaderboard, then search

[skills.sh](https://skills.sh/) ranks by installs, which surfaces the battle-tested options before any search does.

```
npx skills find <query> [--owner <owner>]
```

### 3. Judge the candidate

Recommend nothing on search rank alone. A skill runs with your permissions and your context.

- **Installs** — 1K+ is safe ground. Under 100 needs a reason.
- **Source** — `anthropics`, `vercel-labs`, `cursor`, and named practitioners carry reputation. An unknown author does not.
- **Read the SKILL.md before recommending it.** This is the check that matters and the one that gets skipped. You are about to put its instructions in your own context every session.

### 4. Present, then hand off

Give the user: what it does, installs and source, what you thought of the SKILL.md, and the skills.sh link.

If they want it, dispatch `/add-skill` with the repo and subdir. That is what makes it survive a rebuild.

### 5. Nothing found

Say so and do the task directly. If it is something they do often, `/add-skill` also creates a local skill — and `/writing-for-agents` covers what goes in it.

## Completion

Done when: the user has a named candidate they have accepted or rejected, and any accepted skill went through `/add-skill` rather than `npx skills add`. Checkable: `grep <skill> modules/home/packages/skills.nix` finds it, or the user declined.
