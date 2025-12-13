{
  inputs,
  ...
}:

# ============================================================================
# Code Formatting Configuration
# ============================================================================
# Treefmt configuration for automatic code formatting across multiple languages

{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = _: {
    treefmt = {
      # ============================================================================
      # Formatters
      # ============================================================================
      programs = {
        # Nix
        nixfmt.enable = true; # Nix code formatter
        deadnix.enable = true; # Dead code detector for Nix

        # General
        prettier.enable = true; # Multi-language formatter (JSON, YAML, Markdown, etc.)
        shfmt.enable = true; # Shell script formatter
        actionlint.enable = true; # GitHub Actions linter
        just.enable = true; # Justfile formatter
        taplo.enable = true; # TOML formatter
        yamlfmt.enable = true; # YAML formatter
        stylua.enable = true; # Lua formatter
      };

      # ============================================================================
      # Settings
      # ============================================================================
      settings = {
        # Files to exclude from formatting
        excludes = [
          ".envrc" # Direnv configuration
          ".env" # Environment files
        ];

        # Log level for unmatched files
        on-unmatched = "info";

        # Formatter-specific settings
        formatter = {
          deadnix = {
            no-lambda-arg = true; # Don't warn about lambda args
            no-lambda-pattern-names = true; # Don't warn about lambda pattern names
          };
          prettier.excludes = [
            "config/nvim/nvim-pack-lock.json" # Neovim package lock file
          ];
        };
      };
    };
  };
}
