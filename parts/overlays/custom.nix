_:

{
  # ============================================================================
  # Custom Package Overlays
  # ============================================================================
  # Custom packages built from local derivations

  flake.overlays.custom = final: _: {
    # Custom Hammerspoon build with additional modules
    hammerspoon = final.callPackage ../../darwin/overlays/hammerspoon.nix { };

    # Custom Rift twm build
    rift = final.callPackage ../../darwin/overlays/rift.nix { };
  };
}
