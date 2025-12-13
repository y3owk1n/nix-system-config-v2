{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.rift;
in
{
  options = {
    services.rift = {
      enable = lib.mkEnableOption "Rift window manager";

      package = lib.mkPackageOption pkgs "rift" { };

      config = lib.mkOption {
        type = lib.types.lines;
        default = null;
        description = "Configuration for {file} `rift/config.toml`.";
      };

      configFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to existing config.toml configuration file. Takes precedence over config option.";
      };

      launchd = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Configure the launchd agent to manage the rift process.

            The first time this is enabled, macOS will prompt you to allow this background
            item in System Settings.

            You can verify the service is running correctly from your terminal.
            Run: `launchctl list | grep rift`

            - A running process will show a Process ID (PID) and a status of 0, for example:
              `12345	0	org.nix-community.home.rift`

            - If the service has crashed or failed to start, the PID will be a dash and the
              status will be a non-zero number, for example:
              `-	1	org.nix-community.home.rift`

            In case of failure, check the logs with `cat /tmp/rift.err.log`.

            For more detailed service status, run `launchctl print gui/$(id -u)/org.nix-community.home.rift`.
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
    xdg.configFile."rift/config.toml" =
      if cfg.configFile != null then { source = cfg.configFile; } else { text = cfg.config; };

    # Launch agent for macOS
    launchd.agents.rift = lib.mkIf pkgs.stdenv.isDarwin {
      inherit (cfg.launchd) enable;
      config = {
        ProgramArguments = [
          "${cfg.package}/Applications/Rift.app/Contents/MacOS/Rift"
          "--config"
          "${config.xdg.configHome}/rift/config.toml"
        ];
        RunAtLoad = true;
        KeepAlive = cfg.launchd.keepAlive;
        StandardOutPath = "/tmp/rift.log";
        StandardErrorPath = "/tmp/rift.err.log";
      };
    };
  };
}
