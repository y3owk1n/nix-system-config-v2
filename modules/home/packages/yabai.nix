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
          description = "Configure the launchd agent to manage the yabai process.";
        };
        keepAlive = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether the launchd service should be kept alive.";
        };
      };
    };
  };

  config = lib.mkMerge [
    # Default values
    {
      services.yabai = {
        enable = false;
        config = ''
          yabai -m config layout bsp
          yabai -m config window_placement second_child
          yabai -m config top_padding 8
          yabai -m config bottom_padding 8
          yabai -m config left_padding 8
          yabai -m config right_padding 8
          yabai -m config window_gap 8
          yabai -m config mouse_follows_focus on
          yabai -m config mouse_modifier ctrl
          yabai -m config mouse_action1 move
          yabai -m config mouse_action2 resize
          yabai -m mouse_drop_action swap
        '';
      };
    }
    # Conditional implementation (activated when enabled)
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];

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
    })
  ];
}
