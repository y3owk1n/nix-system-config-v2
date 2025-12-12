{
  inputs,
  ...
}:

{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = _: {
    treefmt = {
      programs = {
        nixfmt.enable = true;
        deadnix.enable = true;
        prettier.enable = true;
        shfmt.enable = true;
        actionlint.enable = true;
        just.enable = true;
        taplo.enable = true;
        yamlfmt.enable = true;
        stylua.enable = true;
      };
      settings = {
        excludes = [
          ".envrc"
          ".env"
        ];
        on-unmatched = "info";
        formatter = {
          deadnix = {
            no-lambda-arg = true;
            no-lambda-pattern-names = true;
          };
          prettier.excludes = [
            "config/nvim/nvim-pack-lock.json"
          ];
        };
      };
    };
  };
}
