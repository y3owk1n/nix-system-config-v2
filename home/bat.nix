{ ... }:
{
  programs.bat = {
    enable = true;
    config = {
      italic-text = "always";
      style = "plain"; # no line numbers, git status, etc... more like cat with colors
    };
  };
}
