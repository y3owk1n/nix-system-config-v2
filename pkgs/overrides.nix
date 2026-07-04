_final: prev: {
  # ============================================================================
  # Package Overrides
  # ============================================================================

  statix = prev.statix.overrideAttrs (_: {
    noCheck = true;
  });

  kanata = prev.kanata.overrideAttrs (
    finalAttrs: _: {
      cargoHash = "sha256-da7kmSvm+z6C+RPqEBEY9PNWxrAEQ8h/ZGDvS9WJ1J8=";
      src = prev.fetchFromGitHub {
        owner = "jtroo";
        repo = "kanata";
        rev = "v1.12.0-prerelease-2";
        sha256 = "sha256-bNUlQBsyGxCu3GHP+qgrYLikLagXxzLjjuZFZFi7Vzk=";
      };
      version = "v1.12.0-prerelease-2";
      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };
      doInstallCheck = false;
    }
  );

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
