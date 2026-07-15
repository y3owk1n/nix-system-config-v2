_final: prev: {
  # ============================================================================
  # Package Overrides
  # ============================================================================

  # TODO: Remove this once statix cache is updated without need to build
  statix = prev.statix.overrideAttrs (_: {
    doCheck = false;
  });

  # BUMP: Latest commit refer here -> https://github.com/christoomey/vim-tmux-navigator
  tmuxPlugins = prev.tmuxPlugins // {
    vim-tmux-navigator = prev.tmuxPlugins.vim-tmux-navigator.overrideAttrs (_: {
      src = prev.fetchFromGitHub {
        owner = "christoomey";
        repo = "vim-tmux-navigator";
        rev = "e41c431a0c7b7388ae7ba341f01a0d217eb3a432";
        hash = "sha256-efqiRffnidYx+qjgsHyWshCFWgZp/ZrHl+Clt04pfpM=";
      };
    });
  };
}
