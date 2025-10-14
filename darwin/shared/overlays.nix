{
  nixos-npm-ls,
  ...
}:
{
  nixpkgs.overlays = [
    (final: prev: {
      # custom derivations
      hammerspoon = final.callPackage ../overlays/hammerspoon.nix { };

      # overrides
      aerospace = prev.aerospace.overrideAttrs (o: rec {
        version = "0.19.2-Beta";
        src = prev.fetchzip {
          url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
          sha256 = "sha256-6RyGw84GhGwULzN0ObjsB3nzRu1HYQS/qoCvzVWOYWQ=";
        };
      });
    })
  ]
  ++ nixos-npm-ls.overlays;
}
