{
  inputs,
  nixpkgs,
  darwin,
  home-manager,
  nix-homebrew,
  catppuccin,
  stylix,
  homebrew-core,
  homebrew-cask,
  homebrew-bundle,
  ...
}:

let
  systemConfig = system: {
    system = system;
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  };
in
{

  # Personal
  "Kyles-MacBook-Air" =
    let
      hostname = "Kyles-MacBook-Air";
      username = "kylewong";
      useremail = "62775956+y3owk1n@users.noreply.github.com"; # only used for git
      githubuser = "y3owk1n";
      githubname = "Kyle Wong";
      gpgkeyid = "F3EBDBB90E035E02";

      inherit (systemConfig "aarch64-darwin") system;
    in
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = inputs // {
        inherit
          system
          username
          useremail
          hostname
          githubuser
          githubname
          ;
      };
      modules = [
        ./hosts/personal-m3.nix
        ./shared/overlays.nix
        stylix.darwinModules.stylix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "bak";
          home-manager.extraSpecialArgs = inputs // {
            inherit
              username
              useremail
              hostname
              githubuser
              githubname
              gpgkeyid
              ;
          };
          home-manager.users.${username} = {
            imports = [
              ../home-manager/default-darwin.nix
              stylix.homeModules.stylix
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
            };

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = true;
            autoMigrate = true;
          };
        }
      ];
    };

  # Work
  "Kyles-iMac" =
    let
      hostname = "Kyles-iMac";
      username = "kylewong";
      useremail = "140996996+mtraworld@users.noreply.github.com";
      githubuser = "mtraworld";
      githubname = "mtraworld";
      gpgkeyid = "B0C4C961630F3318";

      inherit (systemConfig "aarch64-darwin") system;
    in
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = inputs // {
        inherit
          system
          username
          useremail
          hostname
          githubuser
          githubname
          ;
      };
      modules = [
        ./hosts/work-imac.nix
        ./shared/overlays.nix
        stylix.darwinModules.stylix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "bak";
          home-manager.extraSpecialArgs = inputs // {
            inherit
              username
              useremail
              hostname
              githubuser
              githubname
              gpgkeyid
              ;
          };
          home-manager.users.${username} = {
            imports = [
              ../home-manager/default-darwin.nix
              stylix.homeModules.stylix
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
            };

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = false;
          };
        }
      ];
    };

}
