_: {
  # ============================================================================
  # Difftastic
  # ============================================================================

  programs.difftastic = {
    enable = true;
    git = {
      enable = true;
      mode = "both";
    };
    options = {
      background = "dark";
      color = "always";
    };
  };
}
