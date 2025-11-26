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
    enable = false;
  };

  # This is a custom module at ./modules/aerospace.nix
  aerospace = {
    enable = true;
  };

  # add more brew packages here
  homebrew = {
    brews = [
      "opencode"
    ];

    casks = [
      "adobe-creative-cloud"
    ];

    masApps = { };
  };
}
