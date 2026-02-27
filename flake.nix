{
  description = "Kyle Nix Darwin System";

  # ============================================================================
  # Flake Inputs
  # ============================================================================
  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    # ============================================================================
    # Core Nix Ecosystem
    # ============================================================================

    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    # ============================================================================
    # Homebrew Integration
    # ============================================================================

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-y3owk1n = {
      url = "github:y3owk1n/homebrew-tap";
      flake = false;
    };
    homebrew-gechr = {
      url = "github:gechr/homebrew-tap";
      flake = false;
    };

    # ============================================================================
    # Theming & UI
    # ============================================================================

    stylix = {
      url = "https://flakehub.com/f/nix-community/stylix/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ============================================================================
    # Custom Packages & Tools
    # ============================================================================

    nixos-npm-ls.url = "https://flakehub.com/f/y3owk1n/nixos-npm-ls/0.1";
    neru.url = "https://flakehub.com/f/y3owk1n/neru/0.1";
    nvs.url = "https://flakehub.com/f/y3owk1n/nvs/0.1";

    # ============================================================================
    # Development Tools & Infrastructure
    # ============================================================================

    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/0.1";
    treefmt-nix.url = "https://flakehub.com/f/numtide/treefmt-nix/0.1";
    pre-commit-hooks.url = "https://flakehub.com/f/cachix/git-hooks.nix/0.1";
  };

  # ============================================================================
  # Flake Outputs
  # ============================================================================
  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import ./parts/systems.nix;

      imports = [
        ./parts/nixos.nix
        ./parts/darwin.nix
        ./parts/overlays.nix
        ./parts/overlays/custom.nix
        ./parts/overlays/overrides.nix
        ./parts/checks.nix
        ./parts/ci.nix
        ./parts/home-manager.nix
        ./parts/home-manager/shared.nix
        ./parts/treefmt.nix
        ./parts/pre-commit.nix
        ./parts/devshell.nix
      ];

      perSystem =
        { config, system, ... }:
        {
          formatter = config.treefmt.build.wrapper;

          packages = {
            determinate-nixd = inputs.determinate.packages.${system}.default;
            nix = inputs.determinate.inputs.nix.packages.${system}.default;
          };
        };
    };
}
