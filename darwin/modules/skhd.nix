{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.skhd;

  configFile = pkgs.writeScript "skhdrc" cfg.config;
in

{
  options = {
    skhd = with lib.types; {
      enable = lib.mkEnableOption "Skhd (zig)";

      package = lib.mkPackageOption pkgs "skhd" { };

      config = lib.mkOption {
        type = types.lines;
        default = ''
          # launchers
          hyper - b : open -a Safari
          hyper - t : open -a Ghostty
          hyper - n : open -a Notes
          hyper - m : open -a Mail
          hyper - w : open -a WhatsApp
          hyper - f : open ~
          hyper - s : open -a "System Settings"

          # spotlight
          hyper - return : skhd --key "cmd - space"
        '';
        description = "Config to use for {file} `skhdrc`.";
      };
    };
  };

  config = (
    lib.mkIf (cfg.enable) {
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.skhd = {
        command = "${cfg.package}/bin/skhd" + (lib.optionalString (cfg.config != "") " -c ${configFile}");
        serviceConfig = {
          KeepAlive = true;
          RunAtLoad = true;
          ProcessType = "Interactive";
        };
      };
    }
  );
}
