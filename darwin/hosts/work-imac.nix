{
  pkgs,
  username,
  config,
  ...
}:
let
  safariKeys = {
    "New Traworld Window" = "^1";
    "New Madani TRX Window" = "^2";
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
      "adobe-creative-cloud"
      "helium-browser"
    ];

    masApps = { };
  };

  # ============================================================================
  # Nix system packages
  # ============================================================================

  # add more system packages here
  environment.systemPackages = [ ];
}
