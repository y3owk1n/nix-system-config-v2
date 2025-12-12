{
  inputs,
  ...
}:

{
  flake.overlays.custom = final: prev: {
    # Custom derivations
    hammerspoon = final.callPackage ../../darwin/overlays/hammerspoon.nix { };
    rift = final.callPackage ../../darwin/overlays/rift.nix { };
  };
}
