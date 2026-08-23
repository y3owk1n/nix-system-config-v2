# Wide Refactors

A **wide refactor** is one mechanical change (rename a column, retype a shared symbol) whose blast radius fans across the whole codebase. It breaks the vertical-slicing rule because every layer changes for the same reason.

## Expand-contract pattern

1. **Expand**: add the new form beside the old so nothing breaks.
2. **Migrate**: move call sites in batches sized by blast radius. Each batch is its own ticket, blocked by the expand. CI stays green because the old form still exists.
3. **Contract**: delete the old form once no caller remains. This ticket is blocked by every migrate batch.

When batches can't stay green alone, let them share an integration branch. All migrate batches block a final `integrate-and-verify` ticket.
