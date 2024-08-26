{
  description = "Kyle Nix Darwin System";

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";

    # home-manager, used for managing user configuration
    home-manager = {
      # url = "github:nix-community/home-manager/release-24.05";
      url = "github:nix-community/home-manager/master";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
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
        }:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs // {
            inherit
              username
              useremail
              hostname
              githubuser
              ;
          };
          modules = [
            ./modules/nix-core.nix
            ./modules/system.nix
            ./modules/apps.nix
            ./modules/host-users.nix
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
                  ;
              };
              home-manager.users.${username} = import ./home;
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
          useremail = "wongyeowkin@gmail.com";
          githubuser = "y3owk1n";
        };
        "Kyles-iMac" = mkDarwinConfiguration {
          system = "aarch64-darwin";
          hostname = "Kyles-iMac";
          username = "kylewong";
          useremail = "kylewong@traworld.com";
          githubuser = "mtraworld";
        };
      };

      # Keep your formatter configuration
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
      formatter.x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.nixfmt-rfc-style;
    };
}
