{
  inputs,
  ...
}:

{
  imports = [ inputs.pre-commit-hooks.flakeModule ];

  perSystem = _: {
    pre-commit = {
      check.enable = true;
      settings = {
        hooks = {
          treefmt.enable = true;
          # statix and deadnix are checked in the lint derivation which allows warnings
          # statix.enable = true;
          # deadnix.enable = true;
        };
      };
    };
  };
}
