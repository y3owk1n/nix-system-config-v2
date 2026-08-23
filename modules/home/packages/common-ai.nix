_: {
  programs = {
    opencode.enable = true;
    claude-code = {
      enable = true;

      agents = {
        quick = ''
          ---
          name: quick
          description: Trivial tasks: file reads, grep, renames,
            formatting checks, one-line edits, config changes,
            git commands, gh commands. High-volume low-complexity
            work.
          model: haiku
          ---

          Execute completely. Return only the result.
        '';
      };
      context = ''
        ## Approach

        - Read files once. Re-read only when changed.
        - Write tight code: direct, minimal, one purpose per abstraction.
        - Solve only what was asked. Change only what's needed.
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
        - TDD when writing new code or changing behaviour:
          confirm seams, red before green, one slice at a time.
          Tests verify behavior through public interfaces, not
          implementation details. Mock at system boundaries only.

        ## Search Protocol

        - Public URLs → ctx_fetch_and_index(url), then ctx_search.
        - Inline WebFetch only for private/authenticated URLs.

        ## Subagents

        Use **quick** for high-volume trivial work: file reads,
        git/gh commands, grep, one-line edits. Dispatch when
        the task is a single command with no reasoning needed.
      '';
    };
  };
}
