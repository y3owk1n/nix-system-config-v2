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
        - Standards axis: conventions, naming, structure,
          types, error handling, security. Cite the repo
          rule you apply, not a general preference.
        - Spec axis: does the diff do what the spec says and
          no more. Missing criteria, wrong behaviour, scope
          creep. Skip this axis when there is no spec.
        - Rank by cost of being wrong. Skip nits.

        ## Workflow

        - Test after writing. Fix before moving on.
        - Verify output matches expected format.
        - Run the code before declaring done.
        - Test only what the project promises: a behaviour
          listed in prd/behaviours.md, or a public boundary
          (CLI, exported API, route, persisted schema).
        - Never assert the toolchain works. No install, build,
          compile, lint, file-exists, or config-parses tests.
        - Never mirror implementation. Test through public
          interfaces. Mock at system boundaries only.

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
