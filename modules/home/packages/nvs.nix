{ pkgs, config, ... }:
{
  programs.nvs = {
    enable = true;
    # package = pkgs.nvs;
    package = pkgs.nvs-source;
    enableAutoSwitch = false;
    useGlobalCache = true;
  };

  home.sessionVariables = {
    NVS_COLOR_PRIMARY = "#${config.lib.stylix.colors.base0E}";
    NVS_COLOR_TEXT = "#${config.lib.stylix.colors.base05}";
    NVS_COLOR_MUTED = "#${config.lib.stylix.colors.base04}";
    NVS_COLOR_SUBTLE = "#${config.lib.stylix.colors.base03}";
    NVS_COLOR_BORDER = "#${config.lib.stylix.colors.base02}";
    NVS_COLOR_ACCENT = "#${config.lib.stylix.colors.base0D}";
    NVS_COLOR_SUCCESS = "#${config.lib.stylix.colors.base0B}";
    NVS_COLOR_WARNING = "#${config.lib.stylix.colors.base0A}";
    NVS_COLOR_ERROR = "#${config.lib.stylix.colors.base08}";
  };
}
