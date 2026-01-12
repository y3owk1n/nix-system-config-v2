_:

{
  # ============================================================================
  # Custom Package Overlays
  # ============================================================================
  # Custom packages built from local derivations

  flake.overlays.custom = final: _: {
    custom = {
      # Custom Hammerspoon build with additional modules
      hammerspoon = final.callPackage ./custom/hammerspoon.nix { };

      # Custom Rift twm build
      rift = final.callPackage ./custom/rift.nix { };

      # Custom Glide build
      glide = final.callPackage ./custom/glide-wm.nix { };

      # Custom Atuin Run Script (ASR)
      asr = final.callPackage ./custom/asr.nix { };

      # Custom Diagnose Script
      diagnose = final.callPackage ./custom/diagnose.nix { };

      # Move to space script
      move-to-space = final.callPackage ./custom/move-to-space.nix { };

      # Cpenv
      cpenv = final.callPackage ./custom/cpenv.nix { };

      # Cmd
      cmd = final.callPackage ./custom/cmd.nix { };

      # Passx
      passx = final.callPackage ./custom/passx.nix { };
    };
  };
}
