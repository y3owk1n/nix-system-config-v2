{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nvs-source
  ];
}
