{
  inputs,
  ...
}:

let
  lib = inputs.nixpkgs.lib;
in
{
  flake.overlays.default = lib.composeManyExtensions [
    # External overlays
    inputs.neru.overlays.default
    inputs.nvs.overlays.default
    inputs.nixos-npm-ls.overlays.default

    # Custom overlays
    inputs.self.overlays.custom
    inputs.self.overlays.overrides
  ];
}
