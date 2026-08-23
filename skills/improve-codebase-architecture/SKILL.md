---
name: improve-codebase-architecture
description: "Scan codebase for deepening opportunities — refactors that turn shallow modules into deep ones."
disable-model-invocation: true
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities**: refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

## Vocabulary

Use these terms exactly. Prefer: module, interface, implementation, depth, seam, adapter, leverage, locality.

| Term               | Meaning                                                                   |
| ------------------ | ------------------------------------------------------------------------- |
| **module**         | A unit of code with one responsibility                                    |
| **interface**      | The public surface a module exposes to callers                            |
| **implementation** | Everything behind the interface                                           |
| **depth**          | Ratio of implementation to interface — high = deep, low = shallow         |
| **seam**           | A place where two modules meet and can be swapped or tested independently |
| **adapter**        | A module that translates between two interfaces at a seam                 |
| **leverage**       | One interface serving many call sites                                     |
| **locality**       | Related behaviour concentrated in one place                               |

The **deletion test**: would deleting a module concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

## Process

### 1. Explore

**Scope before you scan: YAGNI.** Deepening pays off where future changes happen. Decide where to look before you look.

- If the user named a direction (module, subsystem, pain point), take it.
- Otherwise, walk back the commit history (`git log --oneline`) to find hot spots — files and areas that keep coming up. Let those paths pull your attention.

Read `prd/glossary.md`, `prd/architecture.md`, and `prd/decisions.md` for the area you're touching first.

Then walk the codebase. Note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as implementation?
- Where have pure functions been extracted just for testability, but real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts are untested, or hard to test through their current interface?

### 2. Present candidates as a report

Ask the user: **HTML** (visual, opened in browser) or **Markdown** (terminal-friendly, version-controllable)?

#### HTML

Write a self-contained HTML file to the OS temp directory (`$TMPDIR`, fallback `/tmp`). Write to `<tmpdir>/architecture-review-<timestamp>.html`. Open it for the user (`open <path>` on macOS) and tell them the absolute path.

See `improve-codebase-architecture/HTML-REPORT.md` for the full scaffold, diagram patterns, and styling guidance.

#### Markdown

Write to `<tmpdir>/architecture-review-<timestamp>.md` (`$TMPDIR`, fallback `/tmp`). Return the absolute path.

See `improve-codebase-architecture/MD-REPORT.md` for the full template and diagram patterns.

#### Content (both formats)

Use `prd/glossary.md` vocabulary for the domain. If the glossary defines "Order," say "the Order intake module," not "the FooBarHandler."

If a candidate contradicts an entry in `prd/decisions.md`, only surface it when the friction is real enough to warrant revisiting. Mark clearly: _"contradicts the '{decision title}' decision, but worth reopening because…"_.

For each candidate, render a card with:

- **Files**: which files/modules are involved
- **Problem**: why the current architecture causes friction
- **Solution**: plain English description of what would change
- **Benefits**: in terms of locality and leverage, and how tests improve
- **Before / After diagram**: side-by-side, illustrating shallowness and deepening
- **Recommendation strength**: `Strong` (emerald), `Worth exploring` (amber), or `Speculative` (slate)

End with a **Top recommendation** section: which candidate to tackle first and why.

After the file is written, ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, dispatch `/grill` to walk the decision tree: constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Side effects happen inline as decisions crystallise:

- **Naming a deepened module not in `prd/glossary.md`?** Add the term. Create the file lazily if it doesn't exist.
- **Sharpening a fuzzy term?** Update `prd/glossary.md` right there.
- **Boundary moved?** Update `prd/architecture.md`.
- **User rejects with a load-bearing reason?** Offer a `prd/decisions.md` entry: _"Record this so future reviews don't re-suggest it?"_ Only when the reason matters to a future explorer; skip ephemeral and self-evident ones.

## Completion

Done when: the report is written (HTML or Markdown), the user has picked a candidate, and the grilling loop has produced either a decision or a `prd/decisions.md` entry. Checkable: the report file exists in the expected path, and the user has confirmed which candidate to pursue.
