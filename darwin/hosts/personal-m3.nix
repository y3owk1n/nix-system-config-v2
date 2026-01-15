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
    ../shared/yabai.nix
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

  # ============================================================================
  # Hammerspoon
  # ============================================================================

  # This is a custom module at ./modules/hammerspoon.nix
  hammerspoon = {
    enable = false;
  };

  # ============================================================================
  # Homebrew
  # ============================================================================

  # add more brew packages here
  homebrew = {
    brews = [ ];

    casks = [
      "blender"
      "affinity"
      "helium-browser"
      # "firefox"
    ];

    masApps = { };
  };

  # ============================================================================
  # Nix system packages
  # ============================================================================

  # add more system packages here
  environment.systemPackages = [ ];
}
