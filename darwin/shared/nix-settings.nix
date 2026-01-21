# Nix settings
{
  username,
  ...
}:
{
  # ============================================================================
  # Nix Configuration
  # ============================================================================

  # Custom settings written to /etc/nix/nix.custom.conf
  determinateNix.customSettings = {
    trusted-users = [
      "@admin"
      "root"
      username
    ];
    trusted-substituters = [
      "https://cache.nixos.org"
      "https://cache.flakehub.com"
      "https://install.determinate.systems"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "cache.determinate.systems:aHRYSxYP2rxdNsFfU5Wd0Q8d8Qqjrx4H8YB0uHK7P68="
    ];
    # Enables parallel evaluation (remove this setting or set the value to 1 to disable)
    eval-cores = 0;
    extra-experimental-features = [
      "build-time-fetch-tree" # Enables build-time flake inputs
      "parallel-eval" # Enables parallel evaluation
    ];
    # Other settings
  };

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

}
