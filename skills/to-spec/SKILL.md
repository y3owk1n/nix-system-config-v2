---
name: to-spec
description: "Synthesise the current conversation into a spec and publish it to the tracker."
disable-model-invocation: true
---

# To Spec

Take the current conversation context and codebase understanding and produce a spec. Synthesise from existing context; do not re-interview.

## Labels

Apply `type:spec`, `status:ready-for-agent`, plus one `priority:*` and one `scope:*` from the vocabulary in `triage` SKILL.md.

## Process

### 1. Resolve the tracker

Dispatch a **quick** subagent: `gh auth status && git remote get-url origin`

- If it succeeds, use GitHub.
- Otherwise, ask the user: **GitHub** (creates issues via `gh`) or **local markdown** (writes to `.scratch/`)?

Remember the choice for this session.

### 2. Explore the codebase

Dispatch a **quick** subagent to gather context:

```
cat CONTEXT.md 2>/dev/null || echo "NO_CONTEXT"
ls docs/adr/ 2>/dev/null || echo "NO_ADRS"
```

Use the glossary vocabulary throughout the spec. Respect any ADRs returned.

### 3. Sketch seams

Sketch out the seams at which you're going to test the feature. Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better — the ideal number is one.

Check with the user that these seams match their expectations.

### 4. Write and publish the spec

Compose the spec body using the template below. Include: problem statement, solution, user stories, implementation decisions, testing decisions, out of scope, further notes. See `to-spec/SPEC-TEMPLATE.md` for the full template.

- **GitHub**: dispatch a **quick** subagent to publish:

  ```
  gh issue create \
    --label "type:spec,status:ready-for-agent,<priority>,<scope>" \
    --title "Spec: <feature>" \
    --body "<spec body>"
  ```

  Return the issue URL from quick's output.

- **Local**: dispatch a **quick** subagent to write the file:
  ```
  mkdir -p .scratch/<feature-slug> && cat > .scratch/<feature-slug>/spec.md << 'EOF'
  <spec body>
  EOF
  ```
  Return the file path.

## Completion

Done when: the spec is published (GitHub issue or local file) with all sections filled, labels applied, and seams confirmed with the user. Checkable: dispatch a **quick** subagent to verify the issue exists with the correct labels, or the local file exists with all template sections populated.
