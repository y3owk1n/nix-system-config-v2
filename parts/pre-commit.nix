{
  inputs,
  ...
}:

# ============================================================================
# Pre-commit Hooks Configuration
# ============================================================================
# Automatic code quality checks before commits

{
  imports = [ inputs.pre-commit-hooks.flakeModule ];

  perSystem = _: {
    pre-commit = {
      check.enable = true;

      # ============================================================================
      # Pre-commit Hooks
      # ============================================================================
      settings = {
        hooks = {
          treefmt.enable = true; # Run all formatters
          statix.enable = true; # Nix linter
          deadnix.enable = true; # Dead code detector for Nix
        };
      };
    };
  };
}
