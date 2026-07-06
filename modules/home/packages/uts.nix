{ pkgs, config, ... }:
{
  programs.uts = {
    enable = true;
    package = pkgs.uts-source;
  };

  home.sessionVariables = {
    UTS_COLOR_PRIMARY = "#${config.lib.stylix.colors.base0E}";
    UTS_COLOR_TEXT = "#${config.lib.stylix.colors.base05}";
    UTS_COLOR_MUTED = "#${config.lib.stylix.colors.base04}";
    UTS_COLOR_SUBTLE = "#${config.lib.stylix.colors.base03}";
    UTS_COLOR_BORDER = "#${config.lib.stylix.colors.base02}";
    UTS_COLOR_ACCENT = "#${config.lib.stylix.colors.base0D}";
    UTS_COLOR_SUCCESS = "#${config.lib.stylix.colors.base0B}";
    UTS_COLOR_WARNING = "#${config.lib.stylix.colors.base0A}";
    UTS_COLOR_ERROR = "#${config.lib.stylix.colors.base08}";
  };
}
