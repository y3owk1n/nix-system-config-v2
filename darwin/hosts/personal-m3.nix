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
    ../modules/hyprspace.nix
    ../modules/paneru.nix
    ../modules/rift.nix
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

  # This is a custom module at ./modules/aerospace.nix
  aerospace = {
    enable = true;
  };

  # This is a custom module at ./modules/hyprspace.nix
  hyprspace = {
    enable = false;
  };

  # This is a custom module at ./modules/paneru.nix
  paneru = {
    enable = false;
  };

  # This is a custom module at ./modules/rift.nix
  rift = {
    enable = false;
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
