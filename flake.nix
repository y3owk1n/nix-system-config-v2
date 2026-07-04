{
  description = "Kyle Nix System Configuration";

  # ============================================================================
  # Flake Inputs
  # ============================================================================

  inputs = {
    # Core Nix Ecosystem
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

    # Homebrew Integration
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

    # Theming & UI
    stylix = {
      url = "https://flakehub.com/f/nix-community/stylix/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Custom Packages & Tools
    mimi.url = "https://flakehub.com/f/y3owk1n/mimi/0.1";
    neru.url = "https://flakehub.com/f/y3owk1n/neru/0.1";
    nvs.url = "https://flakehub.com/f/y3owk1n/nvs/0.1";

    # Development Tools & Infrastructure
    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/0.1";
    treefmt-nix.url = "https://flakehub.com/f/numtide/treefmt-nix/0.1";
    pre-commit-hooks.url = "https://flakehub.com/f/cachix/git-hooks.nix/0.1";

    # nixGL for Linux Ghostty
    nixgl.url = "github:nix-community/nixGL";
    nixgl.inputs.nixpkgs.follows = "nixpkgs";
  };

  # ============================================================================
  # Flake Outputs
  # ============================================================================

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      debug = true;
      systems = import ./lib/systems.nix;

      imports = [
        ./pkgs/default.nix
        ./lib/default.nix
        ./lib/treefmt.nix
        ./lib/pre-commit.nix
        ./lib/devshell.nix
      ];

      perSystem =
        { config, system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.self.overlays.default ];
            config.allowUnfree = true;
          };
        in
        {
          _module.args.pkgs = pkgs;

          formatter = config.treefmt.build.wrapper;

          packages = {
            determinate-nixd = inputs.determinate.packages.${system}.default;
            nix = inputs.determinate.inputs.nix.packages.${system}.default;
          };
        };
    };
}
