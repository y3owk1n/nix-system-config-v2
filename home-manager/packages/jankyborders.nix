{ config, ... }:
{
  # ============================================================================
  # Janky Borders Configuration
  # ============================================================================
  # Borders for macOS
  services.jankyborders = {
    enable = true;
    settings = {
      style = "round";
      width = 8.0;
      hidpi = "off";
      active_color = "0xff${config.lib.stylix.colors.base04}";
      inactive_color = "0xff${config.lib.stylix.colors.base02}";
    };
  };
}
