{
  inputs,
  ...
}:

{
  perSystem =
    { system, ... }:
    {
      devShells.default = inputs.nixpkgs.legacyPackages.${system}.mkShell {
        packages = with inputs.nixpkgs.legacyPackages.${system}; [
          nixfmt-rfc-style
          just
          git
          treefmt
          prettier
          shfmt
          statix
          deadnix
        ];
      };
    };
}
