{ pkgs, ... }:
{
  home.packages = with pkgs; [
    custom.diagnose
  ];
}
