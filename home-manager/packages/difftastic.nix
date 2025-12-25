_: {
  # ============================================================================
  # Difftastic
  # ============================================================================

  programs.difftastic = {
    enable = true;
    git = {
      enable = true;
      diffToolMode = true;
    };
    options = {
      background = "dark";
      color = "always";
    };
  };
}
