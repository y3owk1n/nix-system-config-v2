{ username, ... }: {
  # ============================================================================
  # Nix Configuration (Determinate Nix)
  # ============================================================================

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
    eval-cores = 0;
    extra-experimental-features = [
      "build-time-fetch-tree"
      "parallel-eval"
    ];
  };

  nix.channel.enable = false;
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
}
