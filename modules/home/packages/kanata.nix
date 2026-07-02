{ config, pkgs, ... }:
{
  # ============================================================================
  # Kanata Keyboard Remapper
  # ============================================================================
  # Advanced keyboard remapping tool for macOS

  home.packages = with pkgs; [
    kanata
  ];

  # Symlink kanata configuration from the config directory
  xdg.configFile.kanata = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/kanata";
    # recursive = true;
  };
}
