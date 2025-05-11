{ pkgs, ... }:
{
  programs.bat = {
    enable = true;
    config = {
      theme = "catppuccin";
      italic-text = "always";
      style = "plain"; # no line numbers, git status, etc... more like cat with colors
    };
    themes = {
      catppuccin = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat"; # Bat uses sublime syntax for its themes
          rev = "699f60fc8ec434574ca7451b444b880430319941";
          sha256 = "sha256-6fWoCH90IGumAMc4buLRWL0N61op+AuMNN9CAR9/OdI=";
        };
        file = "themes/Catppuccin Macchiato.tmTheme";
      };
    };
  };
}
