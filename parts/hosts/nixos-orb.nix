{ inputs, ... }:

let
  hostname = "nixos-orb";
  username = "kylewong";
  useremail = "62775956+y3owk1n@users.noreply.github.com";
  githubuser = "y3owk1n";
  githubname = "Kyle Wong";
  gpgkeyid = "F3EBDBB90E035E02";
in
if builtins.pathExists /etc/nixos/configuration.nix then
  let
    systemConfig = system: {
      inherit system;
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    };

    inherit (systemConfig "aarch64-linux") system;

  in
  inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = (builtins.removeAttrs inputs [ "self" ]) // {
      inherit
        system
        username
        useremail
        hostname
        githubuser
        githubname
        gpgkeyid
        ;
    };
    modules = [
      # default configurations from orbstack, we don't touch anything to ensure nothing breaks
      /etc/nixos/configuration.nix

      (
        { pkgs, ... }:
        {
          # nix settings
          nix.settings.experimental-features = [
            "nix-command"
            "flakes"
          ];

          # overlays
          nixpkgs.overlays = [ inputs.self.overlays.default ];

          # set shell
          programs.fish.enable = true;
          users.users."${username}".shell = pkgs.fish;

          environment = {
            shells = [ pkgs.fish ];
            # https://github.com/nix-community/home-manager/pull/2408
            pathsToLink = [ "/share/fish" ];
          };

          # add some system packages
          environment.systemPackages = with pkgs; [
            coreutils
            unzip
            zip
            wget
            curl
            vim # just in case neovim breaks or dead, we can still vim instead of nano-ing :(
          ];

          # configure stylix
          stylix = {
            enable = true;
            # base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
            base16Scheme = ../../config/pastel-twilight/base16.yml;
          };
        }
      )

      # stylix
      inputs.stylix.nixosModules.stylix

      # home-manager
      inputs.home-manager.nixosModules.home-manager
      (inputs.self.homeModules.shared {
        inherit
          username
          useremail
          hostname
          githubuser
          githubname
          gpgkeyid
          ;
      })
      {
        home-manager.users.${username} = {
          imports = [
            ../../home-manager/shared/base.nix
            ../../home-manager/hosts/nixos-orb.nix
          ];
        };
      }
    ];
  }
else
  # fallback minimal system
  inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      {
        fileSystems."/".device = "/dev/sda1";
        boot.loader.grub.enable = true;
        boot.loader.grub.devices = [ "/dev/sda" ];
        system.stateVersion = "25.11";
      }
    ];
  }
