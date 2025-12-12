_:

{
  flake.overlays.custom = final: _: {
    # Custom derivations
    hammerspoon = final.callPackage ../../darwin/overlays/hammerspoon.nix { };
    rift = final.callPackage ../../darwin/overlays/rift.nix { };
  };
}
