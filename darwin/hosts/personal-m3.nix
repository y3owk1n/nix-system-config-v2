{
  pkgs,
  username,
  config,
  ...
}:
let
  safariKeys = {
    "New Traworld Window" = "^4";
    "New SKBA Window" = "^3";
    "New MDA Window" = "^2";
    "New Kyle Window" = "^1";
  };
in
{
  imports = [
    ../shared/base.nix
    ../shared/nix-settings.nix
    ../modules/karabiner.nix
    ../modules/aerospace.nix
    ../modules/hammerspoon.nix
    (import ../shared/darwin.nix {
      inherit
        safariKeys
        pkgs
        config
        username
        ;
    })
  ];

  # This is a custom module at ./modules/hammerspoon.nix
  hammerspoon = {
    enable = true;
  };

  # This is a custom module at ./modules/aerospace.nix
  aerospace = {
    enable = true;
    package = (
      pkgs.aerospace.overrideAttrs (o: rec {
        version = "0.19.2-Beta";
        src = pkgs.fetchzip {
          url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
          sha256 = "sha256-6RyGw84GhGwULzN0ObjsB3nzRu1HYQS/qoCvzVWOYWQ=";
        };
      })
    );
  };

  # add more brew packages here
  homebrew = {
    brews = [ ];

    casks = [
      "blender"
    ];

    masApps = { };
  };

}
