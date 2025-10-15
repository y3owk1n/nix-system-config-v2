{
  config,
  lib,
  pkgs,
  ...
}:

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

  config = (
    lib.mkIf (cfg.enable) {
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.hammerspoon = {
        command = "${cfg.package}/Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon";
        serviceConfig = {
          KeepAlive = false;
          RunAtLoad = true;
        };
      };
    }
  );
}
