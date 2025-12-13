{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    pass
    custom.passx
  ];
  home.sessionVariables = {
    PASSWORD_STORE_DIR = "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/pass-store";
  };
}
