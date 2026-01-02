{ inputs, ... }:

{
  flake.overlays.overrides =
    _final: prev:
    let
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev) system config;
      };
    in
    {
      # ============================================================================
      # Unstable Overrides
      # ============================================================================

      inherit (unstable) opencode;

      # ============================================================================
      # Package Overrides
      # ============================================================================

      # Override aerospace to use beta version with latest features
      aerospace = prev.aerospace.overrideAttrs (_: rec {
        version = "0.20.1-Beta";
        src = prev.fetchzip {
          url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
          sha256 = "sha256-avuoflZf4qf7LT5ecF7YKfZgx7uQM4tlLWbPgfujRcY=";
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
            rev = "c45243dc1f32ac6bcf6068e5300f3b2b237e576a";
            hash = "sha256-IEPnr/GdsAnHzdTjFnXCuMyoNLm3/Jz4cBAM0AJBrj8=";
          };
        });
      };
    };
}
