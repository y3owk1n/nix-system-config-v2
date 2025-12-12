{
  inputs,
  ...
}:

{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { system, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          nixfmt.package = inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
          prettier.enable = true;
          shfmt.enable = true;
        };
      };
    };
}
