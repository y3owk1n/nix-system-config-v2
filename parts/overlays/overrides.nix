_:

{
  flake.overlays.overrides = _: prev: {
    # ============================================================================
    # Package Overrides
    # ============================================================================

    # Override aerospace to use beta version with latest features
    aerospace = prev.aerospace.overrideAttrs (_: rec {
      version = "0.20.0-Beta";
      src = prev.fetchzip {
        url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
        sha256 = "sha256-bPcVgTPvskit0/LeqmWoOOnlwwyzPoa48P8Vooaqlig=";
      };
    });

    # Override kanata to use specific version with custom features
    kanata = prev.kanata.overrideAttrs (
      finalAttrs: _: {
        cargoHash = "sha256-2DTL1u17jUFiRoVe7973L5/352GtKte/vakk01SSRwY=";
        src = prev.fetchFromGitHub {
          owner = "jtroo";
          repo = "kanata";
          rev = "v1.10.0";
          sha256 = "sha256-IicVuJZBHzBv9SNGQuWIIaLq2qpWfn/jMFh9KPvAThs=";
        };
        version = "1.10.0";

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
