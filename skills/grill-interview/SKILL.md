---
name: grill-interview
description: "Relentless interview to sharpen a plan or design."
disable-model-invocation: true
---

# Grill Interview

A structured interview to sharpen a plan or design. The agent asks, recommends, and the user picks.

## Format

Every question follows the same pattern:

1. **Question**: what needs sharpening.
2. **Options**: 2-3 concrete choices.
3. **Recommendation**: which one the agent would pick and why (one sentence).
4. **User picks** or overrides with their own.

Keep questions to 3-5 per section. Stop when the plan is solid.

## Sections

### 1. Domain

Open with: "What are we building and for whom?" Then sharpen with:

**Q1: What problem does this solve?**

- A: for users who currently [pain point]
- B: for the system, to enable [capability]
- C: both
- **Recommendation**: [whichever fits the codebase hot spots]

**Q2: Who is the primary user?**

- A: end user (external)
- B: developer (internal)
- C: both, but [X] first
- **Recommendation**: [based on what the codebase already serves]

**Q3: What's the simplest version that proves this works?**

- A: [minimal vertical slice]
- B: [slightly broader but still narrow]
- C: [full scope]
- **Recommendation**: A — tracer bullets, not a cathedral

### 2. Vocabulary

Before questioning, dispatch a **quick** subagent: `cat CONTEXT.md 2>/dev/null || echo "NO_CONTEXT"`

As terms surface, sharpen them:

**Q4: "[term]" — what do you mean exactly?**

- A: [definition 1]
- B: [definition 2]
- **Recommendation**: [whichever matches existing glossary or code]

If the term conflicts with the glossary: "Your glossary defines 'X' as Y, but you seem to mean Z. Which is it?"

If the term is fuzzy: "You're saying '[vague term]': do you mean [A] or [B]? Those are different things."

Stress-test with concrete scenarios. Invent edge cases that force precision.

Cross-reference with code. When the user states how something works, dispatch a **quick** subagent to check whether the code agrees. Surface contradictions.

### 3. Design

For each decision in the plan:

**Q5: "[decision]" — why this way?**

- A: [alternative considered]
- B: [alternative considered]
- C: [what the plan proposes]
- **Recommendation**: C, because [one sentence on leverage or locality]

**Q6: What assumption does this depend on?**

- A: [assumption 1]
- B: [assumption 2]
- **Recommendation**: [which assumption is riskiest]

**Q7: What breaks if that assumption is wrong?**

- A: [failure mode 1]
- B: [failure mode 2]
- **Recommendation**: [which failure is most likely or most costly]

### 4. Interfaces

For each interface:

**Q8: "Who calls this and what do they need?"**

- A: [caller 1] needs [X]
- B: [caller 2] needs [Y]
- **Recommendation**: [simplest shape that serves both]

**Q9: What is the simplest thing that could possibly work?**

- A: [minimal interface]
- B: [slightly richer]
- **Recommendation**: A — you can always add, you can rarely remove

### 5. Boundaries

For each out-of-scope claim:

**Q10: "Why is this out of scope?"**

- A: not enough time
- B: not enough info
- C: genuinely unrelated
- **Recommendation**: [if B, flag it — unknowns are risks, not scope-outs]

**Q11: Does this create a follow-up that blocks something bigger?**

- A: no
- B: yes, [what] blocks [what]
- **Recommendation**: [if B, pull it in now — a blocked dependency is a scheduling bug]

## Close

Summarise what changed:

- Terms sharpened (list them)
- Decisions stress-tested (what held, what didn't)
- Scope adjusted (what moved in or out)
- Open questions (anything unresolved)

## Completion

Done when: all terms have been checked, every design decision has been stress-tested, and the plan is sharper than when it started. Checkable: the user confirms the plan is solid, or has made at least one concrete change to it.
