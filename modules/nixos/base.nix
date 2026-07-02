{ pkgs, username, ... }: {
  # ============================================================================
  # Shared NixOS Base Configuration
  # ============================================================================

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.fish.enable = true;
  users.users."${username}".shell = pkgs.fish;

  environment = {
    shells = [ pkgs.fish ];
    pathsToLink = [ "/share/fish" ];
    localBinInPath = true;
  };

  environment.systemPackages = with pkgs; [
    coreutils
    unzip
    zip
    wget
    curl
    vim
  ];

  programs.nix-ld = {
    enable = true;
    libraries = [ ];
  };
}
