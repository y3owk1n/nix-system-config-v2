{
  nixos-npm-ls,
  pkgs,
  ...
}:
{
  nixpkgs.overlays = [
    (final: prev: {
      # custom derivations
      hammerspoon = final.callPackage ../overlays/hammerspoon.nix { };
      hyprspace = final.callPackage ../overlays/hyprspace.nix { };
      rift = final.callPackage ../overlays/rift.nix { };
      paneru = final.callPackage ../overlays/paneru.nix { };
      govim = final.callPackage ../overlays/govim.nix { };

      # pagkage overrides
      aerospace = prev.aerospace.overrideAttrs (o: rec {
        version = "0.19.2-Beta";
        src = prev.fetchzip {
          url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
          sha256 = "sha256-6RyGw84GhGwULzN0ObjsB3nzRu1HYQS/qoCvzVWOYWQ=";
        };
      });
      kanata = prev.kanata.overrideAttrs (
        finalAttrs: prevAttrs: {
          cargoHash = "sha256-UIpbndTSfEibLbR5hQJ0ff3OvIiW9+Tnmo3omW+g+4c=";
          src = prev.fetchFromGitHub {
            owner = "jtroo";
            repo = "kanata";
            rev = "v1.10.0-prerelease-3";
            sha256 = "sha256-pztEC713GfvI5PJCGwCCKxJahrzFjJ6mL6R1UOxx6Ig=";
          };
          version = "1.10.0-prerelease-3";
          cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) pname src version;
            hash = finalAttrs.cargoHash;
          };
        }
      );

      # tmux plugins overrides
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
    })
  ]
  ++ nixos-npm-ls.overlays;
}
