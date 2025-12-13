{
  inputs,
  ...
}:

{
  perSystem =
    { config, system, ... }:
    {
      # ============================================================================
      # Development Shell
      # ============================================================================
      # Default development environment with essential tools for working on this flake

      devShells.default = inputs.nixpkgs.legacyPackages.${system}.mkShell {
        packages =
          # Essential development tools
          (builtins.attrValues {
            inherit (inputs.nixpkgs.legacyPackages.${system}) just git;
          })
          # Pre-commit hooks tools
          ++ config.pre-commit.settings.enabledPackages
          # Code formatting tools
          ++ (builtins.attrValues config.treefmt.build.programs);

        # Install pre-commit hooks on shell startup
        shellHook = config.pre-commit.installationScript;
      };
    };
}
