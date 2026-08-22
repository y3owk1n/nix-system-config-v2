{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  # ============================================================================
  # Janky Borders Configuration
  # ============================================================================
  # Borders for macOS
  services.jankyborders = {
    enable = true;
    settings = {
      style = "round";
      width = 6.0;
      hidpi = "off";
      active_color = "0xff${config.lib.stylix.colors.base04}";
      inactive_color = "0xff${config.lib.stylix.colors.base02}";
    };
  };
}
