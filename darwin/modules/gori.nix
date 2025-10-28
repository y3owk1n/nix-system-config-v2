{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.gori;

  configFile = pkgs.writeScript "gori.toml" cfg.config;
in

{
  options = {
    gori = with lib.types; {
      enable = lib.mkEnableOption "gori window manager";

      package = lib.mkPackageOption pkgs "gori" { };

      config = lib.mkOption {
        type = types.lines;
        default = ''
          [animation]
          duration_ms = 50
          fps         = 120
          ease_out    = true

          [appearance]
          tile_width     = 1400
          tile_gap       = 8
          padding_top    = 8
          padding_side   = 8
          padding_bottom = 8

          [behavior]
          auto_refresh_on_start = true
          auto_refresh_interval = 0
          auto_focus_on_scroll  = true

          [filters]
          excluded_apps = [
              "Window Server",
              "Dock",
              "Control Center",
              "SystemUIServer",
              "Notification Center",
              "Spotlight"
          ]
          included_apps = []

          [keybindings]
          "cmd+alt+shift+ctrl+f" = "open -a finder"
          "cmd+alt+shift+ctrl+b" = "open -a firefox"
          "cmd+alt+shift+ctrl+t" = "open -a \"Ghostty\""
          "cmd+alt+shift+ctrl+n" = "open -a \"Notes\""
          "cmd+alt+shift+ctrl+m" = "open -a \"Mail\""
          "cmd+alt+shift+ctrl+c" = "open -a \"Calendar\""
          "cmd+alt+shift+ctrl+w" = "open -a \"WhatsApp\""
          "cmd+alt+shift+ctrl+s" = "open -a \"System Preferences\""
          "cmd+alt+shift+ctrl+p" = "open -a \"Passwords\""
          "cmd+alt+shift+ctrl+a" = "open -a \"Activity Monitor\""
          "alt+h" = "${cfg.package}/bin/gori scroll_previous"
          "alt+l" = "${cfg.package}/bin/gori scroll_next"
          "alt+shift+h" = "${cfg.package}/bin/gori move_window_left"
          "alt+shift+l" = "${cfg.package}/bin/gori move_window_right"
          "alt+r" = "${cfg.package}/bin/gori resize_current"
          "alt+shift+r" = "${cfg.package}/bin/gori refresh"

          [window_rules.apps]
          # Terminal = { width = 1000, height = 600 }
          # Chrome   = { width = 1600 }
        '';
        description = "Config to use for {file} `gori.toml`.";
      };
    };
  };

  config = (
    lib.mkIf (cfg.enable) {
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.gori = {
        command =
          "${cfg.package}/bin/gori" + (lib.optionalString (cfg.config != "") " --config-path ${configFile}");
        serviceConfig = {
          KeepAlive = false;
          RunAtLoad = true;
        };
      };
    }
  );
}
