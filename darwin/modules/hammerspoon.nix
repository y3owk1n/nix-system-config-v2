{
  config,
  lib,
  pkgs,
  ...
}:

# ============================================================================
# Hammerspoon Module
# ============================================================================
# macOS automation tool powered by Lua and Objective-C bridge

let
  cfg = config.hammerspoon;
in

{
  options = {
    hammerspoon = {
      enable = lib.mkEnableOption "Hammerspoon";

      package = lib.mkPackageOption pkgs "hammerspoon" { };
    };
  };

  config = {
    environment.systemPackages = lib.mkIf cfg.enable [ cfg.package ];

    launchd.user.agents.hammerspoon = lib.mkIf cfg.enable {
      command = "${cfg.package}/Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon";
      serviceConfig = {
        KeepAlive = false;
        RunAtLoad = true;
      };
    };
  };
}
