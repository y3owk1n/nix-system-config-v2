{ pkgs, ... }:
{
  programs.nvs = {
    enable = true;
    package = pkgs.nvs-source;
    enableAutoSwitch = false;
    useGlobalCache = true;
  };
}
