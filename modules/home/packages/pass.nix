{ config, pkgs, ... }:
let
  storeDir =
    if pkgs.stdenv.isDarwin then
      "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/pass-store"
    else
      "/mnt/mac/Users/kylewong/Library/Mobile Documents/com~apple~CloudDocs/pass-store";
in
{
  home.packages = with pkgs; [
    pass
    custom.passx
  ];
  home.sessionVariables = {
    PASSWORD_STORE_DIR = "${storeDir}";
  };
}
