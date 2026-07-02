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

      package = lib.mkPackageOption pkgs.custom "rift" { };

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
          description = "Configure the launchd agent to manage the rift process.";
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
      services.rift = {
        enable = false;
        config = ''
          [settings]
          default_disable = false
          hot_reload = false
          focus_follows_mouse = false
          mouse_follows_focus = true
          mouse_hides_on_focus = false
          animate = false
          animation_duration = 0.1
          animation_fps = 120.0
          animation_easing = "ease_in_out"

          [settings.layout]
          mode = "dwindle"

          [settings.layout.gaps.outer]
          top = 8
          left = 8
          bottom = 8
          right = 8

          [settings.layout.gaps.inner]
          horizontal = 8
          vertical = 8

          [settings.gestures]
          enabled = true
          fingers = 4

          [settings.ui.menu_bar]
          enabled = true
          show_empty = false
          display_style = "label"
          mode = "active"

          [settings.ui.window_border]
          enabled = true
          width = 3.0
          color = "${config.lib.stylix.colors.base04}"
          roundness = 8.0

          [virtual_workspaces]
          default_workspace_count = 9
          default_workspace = 0
          workspace_names = ["browser", "terminal", "notes", "email", "calendar", "messaging", "design", "screen sharing", "dumpster"]

          app_rules = [
            { app_id = "com.apple.Safari", workspace = "browser" }
            { app_id = "com.apple.SafariTechnologyPreview", workspace = "browser" }
            { app_id = "net.imput.helium", workspace = "browser" }
            { app_id = "org.mozilla.firefox", workspace = "browser" }
            { app_id = "com.mitchellh.ghostty", workspace = "terminal" }
            { app_id = "com.apple.Terminal", workspace = "terminal" }
            { app_id = "com.apple.Notes", workspace = "notes" }
            { app_id = "net.whatsapp.WhatsApp", workspace = "messaging" }
            { app_id = "com.apple.MobileSMS", workspace = "messaging" }
            { app_id = "com.apple.mail", workspace = "email" }
            { app_id = "com.apple.iCal", workspace = "calendar" }
            { app_id = "com.adobe.Photoshop", workspace = "design" }
            { app_id = "com.adobe.illustrator", workspace = "design" }
            { app_id = "org.blenderfoundation.blender", workspace = "design" }
            { app_id = "com.apple.ScreenSharing", workspace = "screen sharing" }
            { app_id = "com.carriez.rustdesk", workspace = "screen sharing" }
            { app_id = "com.apple.systempreferences", floating = true }
          ]

          [modifier_combinations]
          comb1 = "Alt + Shift"
          hyper = "Alt + Ctrl + Shift + Meta"

          [keys]
          "hyper + F" = { exec = ["open", "-a", "finder"] }
          "hyper + B" = { exec = ["open", "-a", "safari"] }
          "hyper + T" = { exec = ["open", "-a", "Ghostty"] }
          "hyper + N" = { exec = ["open", "-a", "Notes"] }
          "hyper + M" = { exec = ["open", "-a", "Mail"] }
          "hyper + C" = { exec = ["open", "-a", "Calendar"] }
          "hyper + W" = { exec = ["open", "-a", "WhatsApp"] }
          "hyper + S" = { exec = ["open", "-a", "System Preferences"] }
          "hyper + P" = { exec = ["open", "-a", "Passwords"] }
          "hyper + A" = { exec = ["open", "-a", "Activity Monitor"] }

          "Alt + H" = { move_focus = "left" }
          "Alt + J" = { move_focus = "down" }
          "Alt + K" = { move_focus = "up" }
          "Alt + L" = { move_focus = "right" }
          "comb1 + H" = { move_node = "left" }
          "comb1 + J" = { move_node = "down" }
          "comb1 + K" = { move_node = "up" }
          "comb1 + L" = { move_node = "right" }

          "hyper + 1" = { switch_to_workspace = "browser" }
          "hyper + 2" = { switch_to_workspace = "terminal" }
          "hyper + 3" = { switch_to_workspace = "notes" }
          "hyper + 4" = { switch_to_workspace = "email" }
          "hyper + 5" = { switch_to_workspace = "calendar" }
          "hyper + 6" = { switch_to_workspace = "messaging" }
          "hyper + 7" = { switch_to_workspace = "design" }
          "hyper + 8" = { switch_to_workspace = "screen sharing" }
          "hyper + 9" = { switch_to_workspace = "dumpster" }

          "comb1 + 1" = { move_window_to_workspace = "browser" }
          "comb1 + 2" = { move_window_to_workspace = "terminal" }
          "comb1 + 3" = { move_window_to_workspace = "notes" }
          "comb1 + 4" = { move_window_to_workspace = "email" }
          "comb1 + 5" = { move_window_to_workspace = "calendar" }
          "comb1 + 6" = { move_window_to_workspace = "messaging" }
          "comb1 + 7" = { move_window_to_workspace = "design" }
          "comb1 + 8" = { move_window_to_workspace = "screen sharing" }
          "comb1 + 9" = { move_window_to_workspace = "dumpster" }

          "Alt + F" = "toggle_window_floating"
          "Alt + M" = "toggle_fullscreen_within_gaps"
          "Alt + Equal" = "resize_window_grow"
          "Alt + Minus" = "resize_window_shrink"
        '';
      };
    }
    # Conditional implementation (activated when enabled)
    (lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];

      xdg.configFile."rift/config.toml" =
        if cfg.configFile != null then { source = cfg.configFile; } else { text = cfg.config; };

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
    })
  ];
}
