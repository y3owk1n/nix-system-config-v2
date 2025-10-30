{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.paneru;
in

{
  options = {
    paneru = {
      enable = lib.mkEnableOption "Paneru window manager";

      package = lib.mkPackageOption pkgs "paneru" { };
    };
  };

  config = (
    lib.mkIf (cfg.enable) {
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.paneru = {
        command = "${cfg.package}/bin/paneru launch";
        serviceConfig = {
          KeepAlive = false;
          RunAtLoad = true;
        };
      };
    }
  );
}
