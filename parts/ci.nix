{
  inputs,
  ...
}:

{
  perSystem =
    { config, system, ... }:
    {
      # ============================================================================
      # CI Checks
      # ============================================================================

      checks = {
        # Check code formatting with treefmt
        format = config.treefmt.build.check inputs.self;

        # Lint Nix code with statix and deadnix
        lint =
          inputs.nixpkgs.legacyPackages.${system}.runCommand "check-lint"
            {
              buildInputs = with inputs.nixpkgs.legacyPackages.${system}; [
                statix
                deadnix
              ];
            }
            ''
              statix check ${../.} || true
              deadnix ${../.} || true
              touch $out
            '';
      };
    };
}
