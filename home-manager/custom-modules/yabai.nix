{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.yabai;
in
{
  options = {
    services.yabai = {
      enable = lib.mkEnableOption "Yabai window manager";

      package = lib.mkPackageOption pkgs "yabai" { };

      config = lib.mkOption {
        type = lib.types.lines;
        default = null;
        description = "Configuration for {file} `yabai/yabairc`.";
      };

      configFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to existing yabairc configuration file. Takes precedence over config option.";
      };

      launchd = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Configure the launchd agent to manage the yabai process.

            The first time this is enabled, macOS will prompt you to allow this background
            item in System Settings.

            You can verify the service is running correctly from your terminal.
            Run: `launchctl list | grep yabai`

            - A running process will show a Process ID (PID) and a status of 0, for example:
              `12345	0	org.nix-community.home.yabai`

            - If the service has crashed or failed to start, the PID will be a dash and the
              status will be a non-zero number, for example:
              `-	1	org.nix-community.home.yabai`

            In case of failure, check the logs with `cat /tmp/yabai.err.log`.

            For more detailed service status, run `launchctl print gui/$(id -u)/org.nix-community.home.yabai`.
          '';
        };
        keepAlive = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether the launchd service should be kept alive.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Generate config file - either from text or source file
    xdg.configFile."yabai/yabairc" =
      if cfg.configFile != null then
        {
          source = cfg.configFile;
          executable = true;
        }
      else
        {
          executable = true;
          text = ''
            export PATH="${cfg.package}/bin:$PATH"
          ''
          + cfg.config;
        };

    # Launch agent for macOS
    launchd.agents.yabai = lib.mkIf pkgs.stdenv.isDarwin {
      inherit (cfg.launchd) enable;
      config = {
        ProgramArguments = [
          "${cfg.package}/bin/yabai"
          "--config"
          "${config.xdg.configHome}/yabai/yabairc"
        ];
        RunAtLoad = true;
        KeepAlive = cfg.launchd.keepAlive;
        StandardOutPath = "/tmp/yabai.log";
        StandardErrorPath = "/tmp/yabai.err.log";
      };
    };
  };
}
