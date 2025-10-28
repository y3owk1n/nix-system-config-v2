{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.rift;

  configFile = pkgs.writeScript "rift.toml" cfg.config;
in

{
  options = {
    rift = with lib.types; {
      enable = lib.mkEnableOption "rift window manager";

      package = lib.mkPackageOption pkgs "rift" { };

      config = lib.mkOption {
        type = types.lines;
        default = ''
          [settings]
          animate = true
          animation_duration = 0.3
          animation_fps = 100.0
          animation_easing = "ease_in_out_cubic"

          default_disable = false

          focus_follows_mouse = true
          mouse_follows_focus = false
          mouse_hides_on_focus = true
          #focus_follows_mouse_disable_hotkey = "Fn"

          auto_focus_blacklist = []

          run_on_start = []

          hot_reload = false

          [settings.layout]
          mode = "bsp"

          [settings.layout.stack]
          stack_offset = 30.0

          default_orientation = "perpendicular"

          [settings.layout.gaps]

          [settings.layout.gaps.outer]
          top = 8
          left = 8
          bottom = 8
          right = 8

          [settings.layout.gaps.inner]
          horizontal = 8
          vertical = 8

          [settings.ui.menu_bar]
          enabled = true
          show_empty = false

          [settings.ui.stack_line]
          enabled = true
          horiz_placement = "top"
          vert_placement = "left"
          thickness = 4.0
          spacing = 2.0

          [settings.ui.mission_control]
          enabled = false
          fade_enabled = false
          fade_duration_ms = 180.0

          [settings.gestures]
          enabled = false
          invert_horizontal_swipe = false
          swipe_vertical_tolerance = 0.4
          skip_empty = true
          fingers = 3
          distance_pct = 0.12
          haptics_enabled = true
          haptic_pattern = "level_change"

          [settings.window_snapping]
          drag_swap_fraction = 0.3

          [virtual_workspaces]
          enabled = true
          default_workspace_count = 9
          auto_assign_windows = true
          preserve_focus_per_workspace = true
          workspace_auto_back_and_forth = false

          default_workspace = 0

          workspace_names = [
          	"browser",
            "terminal",
            "notes",
            "email",
            "calendar",
            "messaging",
            "design",
            "screen sharing",
            "dumpster"
          ]

          app_rules = [
            { app_id = "com.apple.Safari", workspace = "browser" },
            { app_id = "com.apple.SafariTechnologyPreview", workspace = "browser" },
            { app_id = "net.imput.helium", workspace = "browser" },
            { app_id = "org.mozilla.firefox", workspace = "browser" },
            { app_id = "app.zen-browser.zen", workspace = "browser" },
            { app_id = "com.mitchellh.ghostty", workspace = "terminal" },
            { app_id = "com.apple.Terminal", workspace = "terminal" },
            { app_id = "com.apple.Notes", workspace = "notes" },
            { app_id = "net.whatsapp.WhatsApp", workspace = "messaging" },
            { app_id = "com.apple.MobileSMS", workspace = "messaging" },
            { app_id = "com.apple.mail", workspace = "email" },
            { app_id = "com.apple.iCal", workspace = "calendar" },
            { app_id = "com.adobe.Photoshop", workspace = "design" },
            { app_id = "com.adobe.illustrator", workspace = "design" },
            { app_id = "org.blenderfoundation.blender", workspace = "design" },
            { app_id = "com.apple.ScreenSharing", workspace = "screen sharing" },
            { app_id = "com.carriez.rustdesk", workspace = "screen sharing" },
          ]

          [modifier_combinations]
          comb1 = "Alt + Shift"
          hyper = "Alt + Ctrl + Shift + Meta"

          [keys]
          "Alt + H" = { move_focus = "left" }
          "Alt + J" = { move_focus = "down" }
          "Alt + K" = { move_focus = "up" }
          "Alt + L" = { move_focus = "right" }

          "comb1 + H" = { move_node = "left" }
          "comb1 + J" = { move_node = "down" }
          "comb1 + K" = { move_node = "up" }
          "comb1 + L" = { move_node = "right" }

          "Alt + 1" = { switch_to_workspace = "browser" }
          "Alt + 2" = { switch_to_workspace = "terminal" }
          "Alt + 3" = { switch_to_workspace = "notes" }
          "Alt + 4" = { switch_to_workspace = "email" }
          "Alt + 5" = { switch_to_workspace = "calendar" }
          "Alt + 6" = { switch_to_workspace = "messaging" }
          "Alt + 7" = { switch_to_workspace = "design" }
          "Alt + 8" = { switch_to_workspace = "screen sharing" }
          "Alt + 9" = { switch_to_workspace = "dumpster" }

          "comb1 + 1" = { move_window_to_workspace = "browser" }
          "comb1 + 2" = { move_window_to_workspace = "terminal" }
          "comb1 + 3" = { move_window_to_workspace = "notes" }
          "comb1 + 4" = { move_window_to_workspace = "email" }
          "comb1 + 5" = { move_window_to_workspace = "calendar" }
          "comb1 + 6" = { move_window_to_workspace = "messaging" }
          "comb1 + 7" = { move_window_to_workspace = "design" }
          "comb1 + 8" = { move_window_to_workspace = "screen sharing" }
          "comb1 + 9" = { move_window_to_workspace = "dumpster" }

          # "Alt + Shift + Left" = { join_window = "left" }
          # "Alt + Shift + Right" = { join_window = "right" }
          # "Alt + Shift + Up" = { join_window = "up" }
          # "Alt + Shift + Down" = { join_window = "down" }
          # "Alt + Comma" = "stack_windows"
          # "Alt + Shift + Comma" = "toggle_tile_orientation"
          # "Alt + Slash" = "unstack_windows"
          # "Alt + Ctrl + E" = "unjoin_windows" # FIXME: doesnt work

          "Alt + F" = "toggle_window_floating"
          "Alt + M" = "toggle_fullscreen"
          # "Alt + Shift + F" = "toggle_fullscreen_within_gaps"
          # "comb1 + Ctrl + Space" = "toggle_focus_floating" # briefly bring focus to floating window

          # smartly resize windows
          "Alt + Equal" = "resize_window_grow"
          "Alt + Minus" = "resize_window_shrink"

          # if mission control is enabled
          # this will show an exploded view of the windows in the active workspace
          # "Alt + Ctrl + Shift + M" = "show_mission_control_current"
          # this will show the mission control view shown in the readme
          # "Alt + Ctrl + M" = "show_mission_control_all"

          # "Alt + Shift + D" = "debug" # prints layout tree

          # "Alt + Ctrl + S" = "serialize"
          # "Alt + Ctrl + Q" = "save_and_exit"
        '';
        description = "Config to use for {file} `aerospace.toml`.";
      };
    };
  };

  config = (
    lib.mkIf (cfg.enable) {
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.rift = {
        command =
          "${cfg.package}/bin/rift" + (lib.optionalString (cfg.config != "") " --config ${configFile}");
        serviceConfig = {
          KeepAlive = false;
          RunAtLoad = true;
        };
      };
    }
  );
}
