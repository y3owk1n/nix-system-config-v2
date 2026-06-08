{ pkgs, ... }:
{
  # ============================================================================
  # Neru - OS wide keyboard navigation
  # ============================================================================
  # System-wide application for mouse and keyboard control

  services.neru = {
    enable = true;
    # package = pkgs.neru;
    package = pkgs.neru-source;
    config = ''
      # ============================================================================
      # General Settings
      # ============================================================================
      [general]
      hide_overlay_in_screen_share = true
      passthrough_unbounded_keys = true
      exec_shell = "/bin/dash"
      exec_shell_args = ["-lc"]

      # ============================================================================
      # Hotkeys
      # ============================================================================
      [hotkeys]
      "Ctrl+F" = "recursive_grid --cursor-selection-mode hold"
      "Ctrl+S" = ["action move_mouse --selection", "scroll"]

      # Focus window and move cursor to center
      "Alt+H" = "exec mimi action focus_window"
      "Alt+L" = "exec mimi action focus_window --backward"

      # Launchers
      "Cmd+Alt+Shift+Ctrl+F" = "exec open -a \"Finder\""
      # "Cmd+Alt+Shift+Ctrl+B" = "exec open -a \"Brave Browser\""
      # "Cmd+Alt+Shift+Ctrl+B" = "exec open -a \"Helium\""
      "Cmd+Alt+Shift+Ctrl+B" = "exec open -a \"Safari\""
      "Cmd+Alt+Shift+Ctrl+T" = "exec open -a \"Ghostty\""
      "Cmd+Alt+Shift+Ctrl+N" = "exec open -a \"Notes\""
      "Cmd+Alt+Shift+Ctrl+R" = "exec open -a \"Reminders\""
      "Cmd+Alt+Shift+Ctrl+M" = "exec open -a \"Mail\""
      "Cmd+Alt+Shift+Ctrl+C" = "exec open -a \"Calendar\""
      "Cmd+Alt+Shift+Ctrl+W" = "exec open -a \"WhatsApp\""
      "Cmd+Alt+Shift+Ctrl+P" = "exec open -a \"Passwords\""
      "Cmd+Alt+Shift+Ctrl+S" = "exec open -a \"System Settings\""
      "Cmd+Alt+Shift+Ctrl+A" = "exec open -a \"Activity Monitor\""

      "Cmd+Alt+Shift+Ctrl+1" = "exec mimi action space 1"
      "Cmd+Alt+Shift+Ctrl+2" = "exec mimi action space 2"
      "Cmd+Alt+Shift+Ctrl+3" = "exec mimi action space 3"
      "Cmd+Alt+Shift+Ctrl+4" = "exec mimi action space 4"
      "Cmd+Alt+Shift+Ctrl+5" = "exec mimi action space 5"
      "Cmd+Alt+Shift+Ctrl+6" = "exec mimi action space 6"
      "Cmd+Alt+Shift+Ctrl+7" = "exec mimi action space 7"
      "Cmd+Alt+Shift+Ctrl+8" = "exec mimi action space 8"
      "Cmd+Alt+Shift+Ctrl+9" = "exec mimi action space 9"

      "Alt+Shift+1" = ["exec mimi action move_window_to_space 1 && mimi action space 1", "exec mimi action space 1"]
      "Alt+Shift+2" = ["exec mimi action move_window_to_space 2 && mimi action space 2", "exec mimi action space 2"]
      "Alt+Shift+3" = ["exec mimi action move_window_to_space 3 && mimi action space 3", "exec mimi action space 3"]
      "Alt+Shift+4" = ["exec mimi action move_window_to_space 4 && mimi action space 4", "exec mimi action space 4"]
      "Alt+Shift+5" = ["exec mimi action move_window_to_space 5 && mimi action space 5", "exec mimi action space 5"]
      "Alt+Shift+6" = ["exec mimi action move_window_to_space 6 && mimi action space 6", "exec mimi action space 6"]
      "Alt+Shift+7" = ["exec mimi action move_window_to_space 7 && mimi action space 7", "exec mimi action space 7"]
      "Alt+Shift+8" = ["exec mimi action move_window_to_space 8 && mimi action space 8", "exec mimi action space 8"]
      "Alt+Shift+9" = ["exec mimi action move_window_to_space 9 && mimi action space 9", "exec mimi action space 9"]

      # Window manager
      # center window
      "Alt+Shift+C" = "exec mimi action resize_window center"
      # maximise window
      # "Alt+Shift+M" = "exec osascript -e 'tell application \"System Events\" to tell (first process whose frontmost is true) to click menu item \"Fill\" of menu \"Window\" of menu bar 1'"
      "Alt+Shift+M" = "exec mimi action resize_window fill"
      # move to left
      # "Alt+Shift+H" = "exec osascript -e 'tell application \"System Events\" to tell (first process whose frontmost is true) to click menu item \"Left\" of menu \"Move & Resize\" of menu item \"Move & Resize\" of menu \"Window\" of menu bar 1'"
      "Alt+Shift+H" = "exec mimi action resize_window left-half"
      # move to right
      # "Alt+Shift+L" = "exec osascript -e 'tell application \"System Events\" to tell (first process whose frontmost is true) to click menu item \"Right\" of menu \"Move & Resize\" of menu item \"Move & Resize\" of menu \"Window\" of menu bar 1'"
      "Alt+Shift+L" = "exec mimi action resize_window right-half"
      # move to bottom
      # "Alt+Shift+J" = "exec osascript -e 'tell application \"System Events\" to tell (first process whose frontmost is true) to click menu item \"Bottom\" of menu \"Move & Resize\" of menu item \"Move & Resize\" of menu \"Window\" of menu bar 1'"
      "Alt+Shift+J" = "exec mimi action resize_window bottom-half"
      # move to top
      # "Alt+Shift+K" = "exec osascript -e 'tell application \"System Events\" to tell (first process whose frontmost is true) to click menu item \"Top\" of menu \"Move & Resize\" of menu item \"Move & Resize\" of menu \"Window\" of menu bar 1'"
      "Alt+Shift+K" = "exec mimi action resize_window top-half"

      # # Hack to move windows to spaces
      # "Alt+Shift+1" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed ctrl+1", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "action restore_cursor_pos"]
      # "Alt+Shift+2" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed ctrl+2", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "action restore_cursor_pos"]
      # "Alt+Shift+3" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed ctrl+3", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "action restore_cursor_pos"]
      # "Alt+Shift+4" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed ctrl+4", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "action restore_cursor_pos"]
      # "Alt+Shift+5" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed ctrl+5", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "action restore_cursor_pos"]
      # "Alt+Shift+6" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed ctrl+6", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "action restore_cursor_pos"]
      # "Alt+Shift+7" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed ctrl+7", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "action restore_cursor_pos"]
      # "Alt+Shift+8" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed ctrl+8", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "action restore_cursor_pos"]
      # "Alt+Shift+9" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed ctrl+9", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "action restore_cursor_pos"]

      # # If yabai is uninstalled or not working anymore, set these keys in system settings and bear with the animations
      # "Cmd+Alt+Shift+Ctrl+1" = "exec yabai -m space --focus 1"
      # "Cmd+Alt+Shift+Ctrl+2" = "exec yabai -m space --focus 2"
      # "Cmd+Alt+Shift+Ctrl+3" = "exec yabai -m space --focus 3"
      # "Cmd+Alt+Shift+Ctrl+4" = "exec yabai -m space --focus 4"
      # "Cmd+Alt+Shift+Ctrl+5" = "exec yabai -m space --focus 5"
      # "Cmd+Alt+Shift+Ctrl+6" = "exec yabai -m space --focus 6"
      # "Cmd+Alt+Shift+Ctrl+7" = "exec yabai -m space --focus 7"
      # "Cmd+Alt+Shift+Ctrl+8" = "exec yabai -m space --focus 8"
      # "Cmd+Alt+Shift+Ctrl+9" = "exec yabai -m space --focus 9"
      #
      # "Alt+Shift+1" = ["exec yabai -m window --space 1", "exec yabai -m space --focus 1"]
      # "Alt+Shift+2" = ["exec yabai -m window --space 2", "exec yabai -m space --focus 2"]
      # "Alt+Shift+3" = ["exec yabai -m window --space 3", "exec yabai -m space --focus 3"]
      # "Alt+Shift+4" = ["exec yabai -m window --space 4", "exec yabai -m space --focus 4"]
      # "Alt+Shift+5" = ["exec yabai -m window --space 5", "exec yabai -m space --focus 5"]
      # "Alt+Shift+6" = ["exec yabai -m window --space 6", "exec yabai -m space --focus 6"]
      # "Alt+Shift+7" = ["exec yabai -m window --space 7", "exec yabai -m space --focus 7"]
      # "Alt+Shift+8" = ["exec yabai -m window --space 8", "exec yabai -m space --focus 8"]
      # "Alt+Shift+9" = ["exec yabai -m window --space 9", "exec yabai -m space --focus 9"]
      #
      # "Alt+H" = "exec yabai -m window --focus west"
      # "Alt+J" = "exec yabai -m window --focus south"
      # "Alt+K" = "exec yabai -m window --focus north"
      # "Alt+L" = "exec yabai -m window --focus east"
      #
      # "Alt+Shift+H" = "exec yabai -m window --swap west"
      # "Alt+Shift+J" = "exec yabai -m window --swap south"
      # "Alt+Shift+K" = "exec yabai -m window --swap north"
      # "Alt+Shift+L" = "exec yabai -m window --swap east"
      #
      # "Alt+M" = "exec yabai -m window --toggle zoom-fullscreen"
      # "Alt+F" = "exec yabai -m window --toggle float; yabai -m window --grid 4:4:1:1:2:2"

      # ============================================================================
      # Hints
      # ============================================================================
      [hints]
      enabled = false
      visible_check_enabled = false

      hint_characters = "aeudhtnspyfgcrqjkxbmwvz"
      include_menubar_hints = true
      include_dock_hints = true
      include_nc_hints = true
      include_stage_manager_hints = true
      include_pip_hints = true
      include_screen_capture_hints = true
      detect_mission_control = true
      on_mission_control_activated = "hints --action left_click"
      on_mission_control_deactivated = "idle"

      clickable_roles = [
        "AXButton",
        "AXComboBox",
        "AXCheckBox",
        "AXRadioButton",
        "AXLink",
        "AXPopUpButton",
        "AXTextField",
        "AXSlider",
        "AXTabButton",
        "AXSwitch",
        "AXDisclosureTriangle",
        "AXTextArea",
        "AXMenuItem",
        "AXCell",
        "AXRow",
      	"AXMenuButton",
      	"AXGenericElement",
      ]

      additional_menubar_hints_targets = [
        "com.apple.TextInputMenuAgent",
        "com.apple.controlcenter",
        "com.apple.systemuiserver",
        "com.y3owk1n.neru",
      	"com.openai.codex",
      	"com.google.antigravity",
      ]

      [[hints.app_configs]]
      bundle_id = "com.apple.Safari"
      visible_check_enabled = true

      [hints.additional_ax_support]
      enable = true

      additional_electron_bundles = ["com.openai.codex", "com.hnc.discord", "com.google.antigravity"]
      additional_chromium_bundles = []
      additional_firefox_bundles = []
      additional_webkit_bundles = []

      [hints.boundary_highlight]
      enabled = true

      # ============================================================================
      # Grid Navigation
      # ============================================================================
      [grid]
      enabled = false

      # ============================================================================
      # Recursive Grid Navigation
      # ============================================================================
      [recursive_grid]
      enabled = true
      grid_cols = 5
      grid_rows = 5
      keys = "fgcrlaoeuidhtns;qjkxbmwvz"
      min_size_width = 1
      min_size_height = 1

      [recursive_grid.animation]
      enabled = false

      [recursive_grid.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"
      line_width = 1
      # highlight_color = "#B00A1338"
      highlight_color = "#00000000"
      text_color = "#00000000"

      [recursive_grid.hotkeys]
      # disable defaults
      # "Space" = "__disabled__"
      "Shift+L" = "__disabled__"
      "Shift+M" = "__disabled__"
      "Shift+I" = "__disabled__"
      "Shift+U" = "__disabled__"
      "Shift+R" = "__disabled__"
      "`" = "__disabled__"

      "Tab" = "toggle-cursor-follow-selection"

      "'" = "action move_mouse"
      "," = "action move_mouse --center"
      "." = "action reset"
      "p" = "action mouse_down"
      "y" = "action mouse_up"
      "Enter" = "action left_click"
      "Shift+Enter" = "action middle_click"
      "Ctrl+Enter" = "action right_click"
      "Space" = "action left_click"
      "Shift+Space" = "action middle_click"
      "Ctrl+Space" = "action right_click"

      "Ctrl+C" = "idle"
      "Ctrl+J" = "action scroll_down"
      "Ctrl+K" = "action scroll_up"
      "Ctrl+H" = "action scroll_left"
      "Ctrl+L" = "action scroll_right"

      # [[recursive_grid.app_configs]]
      # bundle_id = "com.brave.Browser"
      # hotkeys = {
      #   "1" = ["action right_click", "action sleep 0.1", "action feed o p e n enter m d a enter"],
      #   "2" = ["action right_click", "action sleep 0.1", "action feed o p e n enter s k b enter"],
      #   "3" = ["action right_click", "action sleep 0.1", "action feed o p e n enter t r a enter"],
      #   "4" = ["action right_click", "action sleep 0.1", "action feed o p e n enter m a d enter"],
      #   "5" = ["action right_click", "action sleep 0.1", "action feed o p e n enter w a k enter"],
      # }

      # ============================================================================
      # Scroll
      # ============================================================================

      [scroll]
      scroll_step = 100

      [scroll.hotkeys]
      # disable defaults
      "Shift+L" = "__disabled__"
      "Shift+M" = "__disabled__"
      "Shift+I" = "__disabled__"
      "Shift+U" = "__disabled__"
      "Shift+R" = "__disabled__"

      "Ctrl+C" = "idle"
      "f" = "action feed ctrl+f"

      # [smooth_scroll]
      # enabled = true
      # steps = 300
      # max_duration = 300
      # duration_per_pixel = 20.00

      [mouse_action_indicator]
      enabled = true

      # ============================================================================
      # Mode Indicator
      # ============================================================================
      [mode_indicator.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"

      # [logging]
      # log_level = "debug"
    '';
  };
}
