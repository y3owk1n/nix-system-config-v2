{
  inputs,
  nixpkgs,
  darwin,
  home-manager,
  nix-homebrew,
  stylix,
  homebrew-core,
  homebrew-cask,
  homebrew-bundle,
  homebrew-y3owk1n,
  determinate,
  neru,
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

        # stylix
        stylix.darwinModules.stylix

        # neru
        # neru.darwinModules.default

        # home-manager
        home-manager.darwinModules.home-manager
        (import ../home-manager/shared/config.nix {
          inherit
            username
            useremail
            hostname
            githubuser
            githubname
            gpgkeyid
            inputs
            ;
        })
        {
          home-manager.users.${username} = {
            imports = [
              ../home-manager/shared/base.nix
              ../home-manager/hosts/personal-m3.nix
              # neru
              neru.homeManagerModules.default
            ];
          };
        }

        # determinate
        determinate.darwinModules.default

        # Homebrew
        nix-homebrew.darwinModules.nix-homebrew
        (import ./shared/nix-homebrew.nix {
          inherit
            username
            homebrew-core
            homebrew-cask
            homebrew-bundle
            homebrew-y3owk1n
            ;
        })
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

        # stylix
        stylix.darwinModules.stylix

        # home-manager
        home-manager.darwinModules.home-manager
        (import ../home-manager/shared/config.nix {
          inherit
            username
            useremail
            hostname
            githubuser
            githubname
            gpgkeyid
            inputs
            ;
        })
        {
          home-manager.users.${username} = {
            imports = [
              ../home-manager/shared/base.nix
              ../home-manager/hosts/work-imac.nix
              # neru
              neru.homeManagerModules.default
            ];
          };
        }

        # determinate
        determinate.darwinModules.default

        # Homebrew
        nix-homebrew.darwinModules.nix-homebrew
        (import ./shared/nix-homebrew.nix {
          inherit
            username
            homebrew-core
            homebrew-cask
            homebrew-bundle
            homebrew-y3owk1n
            ;
        })
      ];
    };

}
