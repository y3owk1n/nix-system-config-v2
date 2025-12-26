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

          programs = {
            fish.enable = true;
            nix-ld = {
              enable = true;
              libraries = [
                # Add any missing dynamic libraries for unpackaged programs
                # here, NOT in environment.systemPackages
              ];
            };
            hyprland = {
              enable = true;
              xwayland.enable = true;
            };
            ssh.startAgent = true;
          };

          # set shell
          users.users."${username}".shell = pkgs.fish;

          environment = {
            shells = [ pkgs.fish ];
            # https://github.com/nix-community/home-manager/pull/2408
            pathsToLink = [ "/share/fish" ];
            # Add ~/.local/bin to PATH
            localBinInPath = true;
          };

          # add some system packages
          environment.systemPackages = with pkgs; [
            coreutils
            unzip
            zip
            wget
            curl
            vim # just in case neovim breaks or dead, we can still vim instead of nano-ing :(
            open-vm-tools
            fuse
            firefox
          ];

          # configure stylix
          stylix = {
            enable = true;
            # base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
            base16Scheme = ../../config/pastel-twilight/base16.yml;
          };

          # Network configuration with DNS
          networking.nameservers = [
            "1.1.1.1"
            "1.0.0.1"
          ];

          # VMware Tools and shared folders
          virtualisation.vmware.guest.enable = true;

          # systemd service to mount VMware shared folders
          systemd.services.vmware-shared-folders = {
            description = "Mount VMware shared folders";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.open-vm-tools}/bin/vmhgfs-fuse .host:/ /mnt/hgfs -o allow_other";
              ExecStop = "${pkgs.fuse}/bin/fusermount -u /mnt/hgfs";
            };
            path = [
              pkgs.open-vm-tools
              pkgs.fuse
            ];
          };

          # Hyprland and Wayland support
          hardware.graphics.enable = true;

          # XDG portals
          xdg.portal = {
            enable = true;
            extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          };

          # Fonts
          fonts.packages = with pkgs; [
            nerd-fonts.jetbrains-mono
          ];

          # Polkit
          security.polkit.enable = true;

          # Environment variables for GPU rendering in VM
          environment.sessionVariables = {
            WLR_RENDERER = "pixman";
            LIBGL_ALWAYS_SOFTWARE = "1";
            EGL_PLATFORM = "wayland";
          };

          services = {
            displayManager.gdm = {
              enable = true;
              wayland = true;
            };
            seatd.enable = true;
            pulseaudio.enable = false;
            pipewire = {
              enable = true;
              alsa.enable = true;
              alsa.support32Bit = true;
              pulse.enable = true;
            };
            openssh.enable = true;
          };

          # Enable FUSE for vmhgfs
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
            ../../home-manager/hosts/nixos-vmware-fusion.nix
            # nvs
            inputs.nvs.homeManagerModules.default
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
