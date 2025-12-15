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
        cargoHash = "sha256-Sq7LpUx2VmEMyDds8GDzR5OEMA83DFK8d4/evcxHUBE=";
        src = prev.fetchFromGitHub {
          owner = "jtroo";
          repo = "kanata";
          rev = "v1.10.1-prerelease-1";
          sha256 = "sha256-6cLzlLhNwtheNQPf6bv0rz0ddnocsdoPJBvUs69GZqQ=";
        };
        version = "1.10.1-prerelease-1";

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
