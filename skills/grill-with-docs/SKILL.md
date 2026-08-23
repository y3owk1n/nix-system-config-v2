---
name: grill-with-docs
description: "Relentless interview to sharpen a plan or design, then record decisions."
disable-model-invocation: true
---

# Grill with Docs

A relentless interview to sharpen a plan or design. Dispatches `/grill-interview` for the pure sharpening, then records decisions as ADRs and glossary entries.

## File structure

```
/
├── CONTEXT.md              ← glossary (one per context)
├── CONTEXT-MAP.md          ← only if multi-context repo
├── docs/
│   └── adr/
│       ├── 0001-title.md
│       └── 0002-title.md
```

Create files lazily: only when you have something to write. If no `CONTEXT.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

## Process

### 1. Interview

Dispatch `/grill-interview` to run the pure sharpening interview. Read its output when it returns.

### 2. Record decisions

When a decision crystallised during the interview, offer an ADR — but only when all three are true:

1. **Hard to reverse**: the cost of changing your mind later is meaningful
2. **Surprising without context**: a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off**: there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR.

ADRs live in `docs/adr/` with sequential numbering: `0001-slug.md`, `0002-slug.md`. Dispatch a **quick** subagent to scan for the highest existing number and increment. Then write the ADR file using the format below.

### 3. Check the artefacts

Before finishing, dispatch a **quick** subagent to read `CONTEXT.md` and verify:

- Are all terms used consistently?
- Is every decision recorded?

Report to the user: what was sharpened, what artefacts were created, what still needs attention.

## Completion

Done when: the interview is complete, every hard decision has been offered an ADR (or explicitly skipped with reason), and CONTEXT.md is consistent. Checkable: dispatch a **quick** subagent to read CONTEXT.md and verify no term used in the conversation is missing from the glossary.

## CONTEXT.md format

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
A request for goods or services from a customer.
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request
```

Rules:

- Be opinionated. Pick the best word, list alternatives under `_Avoid_`.
- One or two sentences max. Define what it IS, not what it does.
- Only terms specific to this project. General programming concepts don't belong.
- Group terms under subheadings when natural clusters emerge.

## ADR format

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That's it. An ADR can be a single paragraph. The value is in recording _that_ a decision was made and _why_, not in filling out sections.

Optional sections (only when they add genuine value):

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`)
- **Considered Options**: only when rejected alternatives are worth remembering
- **Consequences**: only when non-obvious downstream effects need to be called out
