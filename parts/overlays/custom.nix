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

    # Custom Atuin Run Script (ASR)
    asr = final.callPackage ../../darwin/overlays/asr.nix { };

    # Cpenv
    cpenv = final.callPackage ../../darwin/overlays/cpenv.nix { };

    # Cmd
    cmd = final.callPackage ../../darwin/overlays/cmd.nix { };

    # Passx
    passx = final.callPackage ../../darwin/overlays/passx.nix { };
  };
}
