{ inputs, lib, ... }:
let
  inherit (lib) composeManyExtensions;
in
{
  flake.overlays.default = composeManyExtensions [
    # External overlays
    inputs.neru.overlays.default
    inputs.mimi.overlays.default
    inputs.nvs.overlays.default

    # Custom overlay
    (final: _prev: {
      custom = {
        gh-actions-language-server = final.callPackage ./custom/gh-actions-language-server.nix { };
        freebuff = final.callPackage ./custom/freebuff.nix { };
        hammerspoon = final.callPackage ./custom/hammerspoon.nix { };
        rift = final.callPackage ./custom/rift.nix { };
        glide = final.callPackage ./custom/glide-wm.nix { };
        asr = final.callPackage ./custom/asr.nix { };
        diagnose = final.callPackage ./custom/diagnose.nix { };
        cpenv = final.callPackage ./custom/cpenv.nix { };
        cmd = final.callPackage ./custom/cmd.nix { };
        passx = final.callPackage ./custom/passx.nix { };
      };
    })

    # Package overrides
    (import ./overrides.nix)
  ];
}
