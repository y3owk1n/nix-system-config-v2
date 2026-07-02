{ pkgs, inputs, ... }: {
  # ============================================================================
  # NixOS UTM VM Profile
  # ============================================================================

  imports = [
    /etc/nixos/configuration.nix
    inputs.niri.nixosModules.niri
  ];

  programs = {
    niri.enable = true;
  };

  environment.systemPackages = with pkgs; [
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

  stylix = {
    enable = true;
    base16Scheme = ../../config/colorschemes/pastel-twilight/base16.yml;
  };

  hardware.graphics.enable = true;

  powerManagement.cpuFreqGovernor = "performance";

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

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
    qemuGuest.enable = true;
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

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome authentication agent";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
  };

  system.stateVersion = "25.11";
}
