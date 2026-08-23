---
name: init-project
description: "Set up project scaffolding for the AI workflow."
disable-model-invocation: true
---

# Init Project

Set up the file structure that other skills expect.

## Scaffolding

```
/
├── CONTEXT.md          ← domain glossary
├── CONTEXT-MAP.md      ← only for multi-context repos
├── docs/
│   └── adr/            ← architecture decision records
└── .scratch/           ← local specs, tickets, reviews (gitignored)
```

## Process

### 1. Check existing state

Dispatch a **quick** subagent:

```
cat CONTEXT.md 2>/dev/null || echo "NO_CONTEXT"
cat CONTEXT-MAP.md 2>/dev/null || echo "NO_MAP"
ls docs/adr/ 2>/dev/null || echo "NO_ADRS"
ls .scratch/ 2>/dev/null || echo "NO_SCRATCH"
grep -q "\.scratch" .gitignore 2>/dev/null && echo "SCRATCH_GITIGNORED" || echo "SCRATCH_NOT_GITIGNORED"
```

### 2. Create missing scaffolding

**CONTEXT.md** — if missing, dispatch a **quick** subagent to seed it:

```
cat > CONTEXT.md << 'EOF'
# {Project Name}

{One sentence: what this project is.}

## Language

{Leave empty — terms will be added as they surface during work.}
EOF
```

Ask the user for the project name and one-liner. If they pass, use it. If not, use a placeholder and tell them to fill it in later.

CONTEXT.md format rules (from `grill-with-docs`):

- Be opinionated. Pick the best word, list alternatives under `_Avoid_`.
- One or two sentences max. Define what it IS, not what it does.
- Only terms specific to this project. General programming concepts don't belong.

**CONTEXT-MAP.md** — only if the repo has multiple distinct contexts (e.g. frontend + backend). Ask the user: **multi-context repo?** If yes, dispatch a **quick** subagent to create a stub:

```
cat > CONTEXT-MAP.md << 'EOF'
# Context Map

| Context | Description | Key terms |
|---|---|---|
| {name} | {what it covers} | {link to CONTEXT.md or separate glossary} |
EOF
```

**docs/adr/** — if missing, dispatch a **quick** subagent:

```
mkdir -p docs/adr
```

**.scratch/** — if missing, dispatch a **quick** subagent:

```
mkdir -p .scratch
```

### 3. Gitignore .scratch

If `.scratch` is not gitignored, ask the user: **gitignore .scratch?** (recommended — local specs and reviews are rarely worth committing).

If yes, dispatch a **quick** subagent to append to `.gitignore`:

```
printf '\n.scratch/\n' >> .gitignore
```

### 4. Report

Summarise what was created and what already existed:

- CONTEXT.md: [created / already exists]
- CONTEXT-MAP.md: [created / already exists / skipped — not multi-context]
- docs/adr/: [created / already exists]
- .scratch/: [created / already exists]
- .scratch gitignored: [yes / no]

## Completion

Done when: all scaffolding exists, and the user has decided on .scratch gitignore and multi-context. Checkable: dispatch a **quick** subagent to verify CONTEXT.md exists, docs/adr/ exists, and .scratch/ exists.
