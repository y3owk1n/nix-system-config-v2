_: {
  perSystem =
    { config, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages =
          with pkgs;
          [
            just
            just-lsp
            git
            lua-language-server
            stylua
            nixd
          ]
          ++ config.pre-commit.settings.enabledPackages
          ++ (builtins.attrValues config.treefmt.build.programs);

        shellHook = config.pre-commit.installationScript;
      };
    };
}
