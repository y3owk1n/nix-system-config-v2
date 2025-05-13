{
  description = "Kyle Nix Darwin System";

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";

    # home-manager, used for managing user configuration
    home-manager = {
      # url = "github:nix-community/home-manager/release-24.05";
      url = "github:nix-community/home-manager";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin.url = "github:LnL7/nix-darwin";

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

    y3owk1n-tap = {
      url = "github:y3owk1n/homebrew-tap";
      flake = false;
    };

    catppuccin.url = "github:catppuccin/nix";
  };

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs =
    inputs@{
      self,
      nixpkgs,
      darwin,
      home-manager,
      nix-homebrew,
      catppuccin,
      homebrew-core,
      homebrew-cask,
      homebrew-bundle,
      y3owk1n-tap,
      ...
    }:
    let
      # Define a function to create a configuration for each machine
      mkDarwinConfiguration =
        {
          system,
          hostname,
          username,
          useremail,
          githubuser,
          githubname,
        }:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs // {
            inherit
              username
              useremail
              hostname
              githubuser
              githubname
              ;
          };
          modules = [
            ./modules/nix-core.nix
            ./modules/system.nix
            ./modules/apps.nix
            ./modules/host-users.nix
            ./modules/yabai.nix
            ./modules/custom/karabiner.nix
            ./modules/custom/cmd.nix
            ./modules/custom/aerospace.nix
            # home manager
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = inputs // {
                inherit
                  username
                  useremail
                  hostname
                  githubuser
                  githubname
                  ;
              };
              home-manager.users.${username} = {
                imports = [
                  ./home
                  # catppuccin global
                  catppuccin.homeModules.catppuccin
                ];
              };
            }
            # Homebrew
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                # Install Homebrew under the default prefix
                enable = true;

                # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
                enableRosetta = true;

                # User owning the Homebrew prefix
                user = username;

                # Optional: Declarative tap management
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                  "y3owk1n/homebrew-tap" = y3owk1n-tap;
                };

                # Optional: Enable fully-declarative tap management
                #
                # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
                mutableTaps = false;
              };
            }
          ];
        };
    in
    {
      # Define configurations for each machine
      darwinConfigurations = {
        "Kyles-MacBook-Air" = mkDarwinConfiguration {
          system = "aarch64-darwin";
          hostname = "Kyles-MacBook-Air";
          username = "kylewong";
          useremail = "62775956+y3owk1n@users.noreply.github.com"; # only used for git
          githubuser = "y3owk1n";
          githubname = "Kyle Wong";
        };
        "Kyles-iMac" = mkDarwinConfiguration {
          system = "aarch64-darwin";
          hostname = "Kyles-iMac";
          username = "kylewong";
          useremail = "140996996+mtraworld@users.noreply.github.com";
          githubuser = "mtraworld";
          githubname = "mtraworld";
        };
      };

      # Keep your formatter configuration
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
      formatter.x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.nixfmt-rfc-style;
    };
}
