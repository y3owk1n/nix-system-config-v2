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
    enable = false;
  };

  # add more brew packages here
  homebrew = {
    brews = [
      "opencode"
    ];

    casks = [
      "blender"
    ];

    masApps = { };
  };

}
