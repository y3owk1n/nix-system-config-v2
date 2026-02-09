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
      version = "7.1.16";
      src = fetchTarball {
        url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
        sha256 = "sha256:133b49xff3fmf2zj16h48ygpdxr26sfs9wmavs2igsmdqslvwhxc";
      };
    });

    # Override kanata to use specific version with custom features
    kanata = prev.kanata.overrideAttrs (
      finalAttrs: _: {
        cargoHash = "sha256-qYFt/oHokR+EznugEaE/ZEn26IFVLXePgoYGxoPRi+g=";
        src = prev.fetchFromGitHub {
          owner = "jtroo";
          repo = "kanata";
          rev = "v1.10.1";
          sha256 = "sha256-jzTK/ZK9UrXTP/Ow662ENBv3cim6klA8+DQv4DLVSNU=";
        };
        version = "1.10.1";

        cargoDeps = prev.rustPlatform.fetchCargoVendor {
          inherit (finalAttrs) pname src version;
          hash = finalAttrs.cargoHash;
        };
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
