{
  inputs,
  ...
}:

{
  perSystem =
    { config, system, ... }:
    {
      devShells.default = inputs.nixpkgs.legacyPackages.${system}.mkShell {
        packages =
          (builtins.attrValues {
            inherit (inputs.nixpkgs.legacyPackages.${system}) just git;
          })
          ++ config.pre-commit.settings.enabledPackages
          ++ (builtins.attrValues config.treefmt.build.programs);
        shellHook = config.pre-commit.installationScript;
      };
    };
}
