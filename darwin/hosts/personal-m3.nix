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
      "blender"
    ];

    masApps = { };
  };

}
