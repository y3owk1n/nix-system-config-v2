_: {
  # ============================================================================
  # Starship Prompt Configuration
  # ============================================================================
  # Minimal prompt configuration with only essential modules enabled.
  # Most modules are disabled to keep the prompt clean and fast.

  programs.starship = {
    enable = true;
    enableTransience = true;
    settings = {
      command_timeout = 3000; # set longer to give it some time to warmup
      git_status = {
        ahead = "⇡$count";
        behind = "⇣$count";
        deleted = "✘$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        modified = "!$count";
        renamed = "»$count";
        staged = "+$count";
        stashed = "\\$$count";
        untracked = "?$count";
        ignore_submodules = true;
      };

      # symbols
      directory.read_only = " 󰌾";
      docker_context.symbol = " ";
      git_branch.symbol = " ";
      git_commit.tag_symbol = "  ";
      golang.symbol = "󰟓 ";
      lua.symbol = " ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";

      # enable
      direnv.disabled = false;
    };
  };

  # ============================================================================
  # Fish Integration
  # ============================================================================

  programs.fish.functions.starship_transient_prompt_func = {
    description = "Starship transient prompt";
    body = ''
      # Show only the character module in transient (continuation) prompts
      starship module character
    '';
  };
}
