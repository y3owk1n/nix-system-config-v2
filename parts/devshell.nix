{
  inputs,
  ...
}:

{
  perSystem =
    { config, system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.self.overlays.default ];
      };
    in
    {
      # ============================================================================
      # Development Shell
      # ============================================================================
      # Default development environment with essential tools for working on this flake

      # Make the overlayed pkgs available to other perSystem modules
      _module.args.pkgs = pkgs;

      devShells.default = pkgs.mkShell {
        packages =
          with pkgs;
          [
            # Essential development tools
            just
            just-lsp
            git
            lua-language-server
            stylua
            nixd
          ]
          # Pre-commit hooks tools
          ++ config.pre-commit.settings.enabledPackages
          # Code formatting tools
          ++ (builtins.attrValues config.treefmt.build.programs);

        # Install pre-commit hooks on shell startup
        shellHook = config.pre-commit.installationScript;
      };
    };
}
