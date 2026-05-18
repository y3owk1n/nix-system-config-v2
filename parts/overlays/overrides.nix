_: {
  flake.overlays.overrides = _final: prev: {
    # ============================================================================
    # Package Overrides
    # ============================================================================

    # Override aerospace to use beta version with latest features
    aerospace = prev.aerospace.overrideAttrs (_: rec {
      version = "0.20.2-Beta";
      src = prev.fetchzip {
        url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
        sha256 = "sha256-PyWHtM38XPNkkEZ0kACPia0doR46FRpmSoNdsOhU4uw=";
      };
    });

    # Override yabai to use the specific version
    yabai = prev.yabai.overrideAttrs (_: rec {
      version = "7.1.25";
      src = fetchTarball {
        url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
        sha256 = "sha256:12glpxnxf5x6mdgkgr9p7w02x80y2l7626rknraknrkkishlnrl4";
      };
    });

    # Override kanata to use specific version with custom features
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

        doInstallCheck = false; # do not check for --version matches for prereleases
      }
    );

    # ============================================================================
    # Tmux Plugin Overrides
    # ============================================================================

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
  };
}
