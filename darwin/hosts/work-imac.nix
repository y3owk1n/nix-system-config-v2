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
    (import ../shared/darwin.nix {
      inherit
        safariKeys
        pkgs
        config
        username
        ;
    })
  ];

  # add more brew packages here
  homebrew = {
    brews = [ ];

    casks = [
      "adobe-creative-cloud"
    ];

    masApps = { };
  };
}
