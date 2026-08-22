_: {
  programs = {
    opencode.enable = true;
    claude-code.enable = true;
    claude-code.context = ''
      ## Approach

      - Read files once. Re-read only when changed.
      - Write tight code: direct, minimal, one purpose per abstraction.
      - Solve only what was asked.
      - Change only what's needed.
      - Verify APIs, versions, flags, and package names from source.
      - Surface errors with full context.
      - Code first, explanation after only when non-obvious.
      - ASCII punctuation only.

      ## Review

      - One pass: state the bug, show the fix, stop.

      ## Workflow

      - Test after writing. Fix before moving on.
      - Verify output matches expected format.
      - Run the code before declaring done.

      ## Search Protocol

      - Public URLs → ctx_fetch_and_index(url), then ctx_search.
      - Inline WebFetch only for private/authenticated URLs.
    '';
  };
}
