{ pkgs, ... }:
{
  home.packages = with pkgs; [
    discord
    whatsapp-for-mac
  ];
}
