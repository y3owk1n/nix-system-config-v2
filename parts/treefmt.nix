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
          nixfmt = {
            enable = true;
            package = inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
          };
          prettier = {
            enable = true;
            excludes = [
              "config/nvim/nvim-pack-lock.json"
            ];
          };
          shfmt.enable = true;
        };
      };
    };
}
