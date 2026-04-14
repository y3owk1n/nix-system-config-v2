{ inputs, ... }:

let
  hostname = "nixos-utm";
  username = "kylewong";
  useremail = "62775956+y3owk1n@users.noreply.github.com";
  githubuser = "y3owk1n";
  githubname = "Kyle Wong";
  gpgkeyid = "F3EBDBB90E035E02";

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

    inputs.niri.nixosModules.niri

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
          niri.enable = true;
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
          firefox
          niri
          waybar
          fuzzel
          mako
          wl-clipboard
          grim
          slurp
          swaylock-effects
          swayidle
          brightnessctl
          playerctl
          xwayland-satellite
          neru-source
          alacritty
          kitty
        ];

        # configure stylix
        stylix = {
          enable = true;
          # base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
          base16Scheme = ../../config/pastel-twilight/base16.yml;
        };

        # Wayland support
        hardware.graphics.enable = true;

        # A few performance-friendly defaults for VMs
        powerManagement.cpuFreqGovernor = "performance";

        # Fonts
        fonts.packages = with pkgs; [
          nerd-fonts.jetbrains-mono
        ];

        # Environment variables for GPU rendering in VM
        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
          MOZ_ENABLE_WAYLAND = "1";
        };

        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gnome
            pkgs.xdg-desktop-portal-gtk
          ];
          config.common.default = "*";
        };

        services = {
          # UTM/QEMU guest tweaks (Apple Silicon)
          qemuGuest.enable = true;

          # Better clipboard + (sometimes) dynamic resolution when using SPICE/QEMU backend
          spice-vdagentd.enable = true;

          greetd = {
            enable = true;
            settings.default_session = {
              command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd niri-session";
              user = "greeter";
            };
          };
          openssh.enable = true;

          pipewire = {
            enable = true;
            pulse.enable = true;
            alsa.enable = true;
            alsa.support32Bit = false;
          };

          dbus.enable = true;
        };

        security = {
          rtkit.enable = true;
          polkit.enable = true;
        };

        # Autostart polkit agent for GUI auth prompts
        systemd.user.services.polkit-gnome-authentication-agent-1 = {
          description = "polkit-gnome authentication agent";
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            Restart = "on-failure";
          };
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
          ../../home-manager/hosts/nixos-utm.nix
          # nvs
          inputs.nvs.homeManagerModules.default
        ];
      };
    }
  ];
}
