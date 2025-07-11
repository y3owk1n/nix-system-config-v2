{
  username,
  hostname,
  pkgs,
  ...
}:
{
  system.defaults.smb.NetBIOSName = hostname;

  networking = {
    hostName = hostname;
    computerName = hostname;
    applicationFirewall = {
      enable = true;
      blockAllIncoming = true;
      enableStealthMode = true;
    };
  };

  nix.settings.trusted-users = [ username ];

  # enable flakes globally
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.channel.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  nix.enable = false;

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  # Use this instead of services.nix-daemon.enable if you
  # don't wan't the daemon service to be managed for you.
  # nix.useDaemon = true;

  # nix.package = pkgs.nixVersions.latest;
  # nix.package = pkgs.nix;
  # nix.package = pkgs.nixVersions.nix_2_29; # Explicit version
  # nix.package = pkgs.nixVersions.git;

  # do garbage collection weekly to keep disk usage low
  # nix.gc = {
  #   automatic = lib.mkDefault true;
  #   options = lib.mkDefault "--delete-older-than 7d";
  # };

  # Disable auto-optimise-store because of this issue:
  #   https://github.com/NixOS/nix/issues/7273
  # "error: cannot link '/nix/store/.tmp-link-xxxxx-xxxxx' to '/nix/store/.links/xxxx': File exists"
  # nix.settings = {
  #   auto-optimise-store = false;
  # };

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.fish.enable = true;
  # environment.shells = [ pkgs.fish ];

  environment.systemPackages = with pkgs; [
    coreutils
  ];

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };
}
