{
  inputs,
  ...
}:

{
  perSystem =
    { config, system, ... }:
    {
      checks = {
        format = config.treefmt.build.check inputs.self;

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
