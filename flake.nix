{
  description = "Kyle Nix Darwin System";

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2511";
    # nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";

    # home-manager, used for managing user configuration
    home-manager = {
      # url = "github:nix-community/home-manager/release-25.11";
      url = "https://flakehub.com/f/nix-community/home-manager/0.2511";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.2511";
      # url = "github:lnl7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

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
      url = "github:Homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-y3owk1n = {
      url = "github:y3owk1n/homebrew-tap";
      flake = false;
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      # NOTE: can't use flakehub for it, as we need to use the same version as nix darwin and nixpkgs
      # url = "https://flakehub.com/f/nix-community/stylix/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-npm-ls.url = "https://flakehub.com/f/y3owk1n/nixos-npm-ls/0.1";

    neru.url = "https://flakehub.com/f/y3owk1n/neru/0.1";

    nvs.url = "https://flakehub.com/f/y3owk1n/nvs/0.1";
  };

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs =
    inputs@{
      nixpkgs,
      darwin,
      home-manager,
      nix-homebrew,
      stylix,
      homebrew-core,
      homebrew-cask,
      homebrew-bundle,
      homebrew-y3owk1n,
      nixos-npm-ls,
      determinate,
      neru,
      nvs,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    {
      darwinConfigurations = (
        import ./darwin {
          inherit (nixpkgs) lib;
          inherit
            inputs
            nixpkgs
            home-manager
            darwin
            nix-homebrew
            stylix
            homebrew-core
            homebrew-cask
            homebrew-bundle
            homebrew-y3owk1n
            nixos-npm-ls
            determinate
            neru
            nvs
            ;
        }
      );

      # Keep your formatter configuration
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
