_: {
  programs = {
    opencode.enable = true;
    claude-code.enable = true;
    claude-code.context = ''
      ## Approach

      - Read files once. Re-read only when changed.
      - Write tight code: direct, minimal, one purpose per abstraction.
      - Solve only what was asked. No speculative additions.
      - Change only what's needed. Leave untouched code untouched.
      - Verify APIs, versions, flags, and package names from source.
      - Surface errors with full context. No silent catches.
      - Code first, explanation after only when non-obvious.
      - ASCII punctuation only. No emojis, em-dashes, hyphens, or decorative Unicode.

      ## Review

      - One pass: state the bug, show the fix, stop.

      ## Workflow

      - Test after writing. Fix before moving on.
      - Verify output matches expected format.
      - Never declare done without running the code.

      ## Search Protocol

      - Public URLs → ctx_fetch_and_index(url), then ctx_search.
      - Inline WebFetch only for private/authenticated URLs.

      ## Model Selection

      **opus-5:** Architecture, security reviews, 5+ file refactors, requirements.
      **sonnet-5:** Standard coding, CRUD, config edits, CI triage.
      **haiku-4.5:** Code lookup, single-function questions, diff review.

      ## Effort

      - `xhigh` budget: architectural decisions only.
      - Default budget: CRUD and routine tasks.
    '';
  };
}
