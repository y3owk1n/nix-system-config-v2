{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cobra-cli
  ];

  programs.go = {
    enable = true;
    telemetry.mode = "off";
  };
}
