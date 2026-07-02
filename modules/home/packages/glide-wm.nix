{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.glide-wm;
in
{
  options = {
    services.glide-wm = {
      enable = lib.mkEnableOption "Glide window manager";

      package = lib.mkPackageOption pkgs.custom "glide" { };

      config = lib.mkOption {
        type = lib.types.lines;
        default = null;
        description = "Configuration for {file} `glide/config.toml`.";
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
          description = "Configure the launchd agent to manage the glide process.";
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
      services.glide-wm = {
        enable = false;
        config = ''
          [settings]
          animate = false
          default_disable = false
          focus_follows_mouse = false
          mouse_follows_focus = true
          mouse_hides_on_focus = false
          outer_gap = 8
          inner_gap = 8
          group_bars.enable = false

          [keys]
          "Alt + Z" = "toggle_space_activated"
          "Alt + H" = { move_focus = "left" }
          "Alt + J" = { move_focus = "down" }
          "Alt + K" = { move_focus = "up" }
          "Alt + L" = { move_focus = "right" }
          "Alt + Shift + H" = { move_node = "left" }
          "Alt + Shift + J" = { move_node = "down" }
          "Alt + Shift + K" = { move_node = "up" }
          "Alt + Shift + L" = { move_node = "right" }
          "Alt + F" = "toggle_window_floating"
          "Alt + M" = "toggle_fullscreen"

          [settings.experimental]
          status_icon.enable = true
          status_icon.space_index = true
          status_icon.color = false
        '';
      };
    }
    # Conditional implementation (activated when enabled)
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];

      xdg.configFile."glide/config.toml" =
        if cfg.configFile != null then { source = cfg.configFile; } else { text = cfg.config; };

      launchd.agents.glide-wm = lib.mkIf pkgs.stdenv.isDarwin {
        inherit (cfg.launchd) enable;
        config = {
          ProgramArguments = [
            "${cfg.package}/Applications/Glide.app/Contents/MacOS/glide_server"
            "--config"
            "${config.xdg.configHome}/glide/config.toml"
          ];
          RunAtLoad = true;
          KeepAlive = cfg.launchd.keepAlive;
          StandardOutPath = "/tmp/glide.log";
          StandardErrorPath = "/tmp/glide.err.log";
        };
      };
    })
  ];
}
