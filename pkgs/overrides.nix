_final: prev: {
  # ============================================================================
  # Package Overrides
  # ============================================================================

  # TODO: Remove this once statix cache is updated without need to build
  statix = prev.statix.overrideAttrs (_: {
    noCheck = true;
  });

  # TODO: Remove this once the nixpkgs version is updated to 1.12.0
  # BUMP: Latest version refer here -> https://github.com/jtroo/kanata/releases/latest
  kanata = prev.kanata.overrideAttrs (
    finalAttrs: _: {
      cargoHash = "sha256-4UBN4I35ZPPPL68LxxPna9Fs9sATCiwoTbWgHYwqOjs=";
      src = prev.fetchFromGitHub {
        owner = "jtroo";
        repo = "kanata";
        rev = "v1.12.0";
        sha256 = "sha256-WjdmjgEMoo3QNqT4yWxaKOkfuRLdNg4Im+V1Hy5vWgY=";
      };
      version = "v1.12.0";
      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };
      doInstallCheck = false;
    }
  );

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
