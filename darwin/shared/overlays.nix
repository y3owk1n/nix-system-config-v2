{
  nixos-npm-ls,
  ...
}:
{
  nixpkgs.overlays = [
    (final: prev: {
      # custom derivations
      hammerspoon = final.callPackage ../overlays/hammerspoon.nix { };
      imageoptim-for-mac = final.callPackage ../overlays/imageoptim-for-mac.nix { };
      onyx-for-mac = final.callPackage ../overlays/onyx-for-mac.nix { };
      orbstack = final.callPackage ../overlays/orbstack.nix { };

      # overrides
      aerospace = prev.aerospace.overrideAttrs (o: rec {
        version = "0.19.2-Beta";
        src = prev.fetchzip {
          url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
          sha256 = "sha256-6RyGw84GhGwULzN0ObjsB3nzRu1HYQS/qoCvzVWOYWQ=";
        };
      });
      whatsapp-for-mac = prev.whatsapp-for-mac.overrideAttrs (o: rec {
        version = "2.25.28.75";
        src = prev.fetchzip {
          extension = "zip";
          name = "WhatsApp.app";
          url = "https://web.whatsapp.com/desktop/mac_native/release/?version=${version}&extension=zip&configuration=Release&branch=relbranch";
          hash = "sha256-Ygfg2iEhfzL2qj6RjTq0viZ0Pitx66bw6oDk2Hdd4SQ=";
        };
      });
    })
  ]
  ++ nixos-npm-ls.overlays;
}
