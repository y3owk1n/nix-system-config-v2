{ config, ... }:
{
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--hidden"
      "--glob=!.git/*"
      "--smart-case"
    ];
  };
  home.sessionVariables = {
    RIPGREP_CONFIG_PATH = "${config.home.homeDirectory}/.config/ripgrep/ripgreprc";
  };
}
