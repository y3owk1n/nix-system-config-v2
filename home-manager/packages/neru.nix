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

      # ============================================================================
      # Hotkeys
      # ============================================================================
      [hotkeys]
      # disable defaults
      "Cmd+Shift+Space" = "__disabled__"
      "Cmd+Shift+G" = "__disabled__"
      "Cmd+Shift+C" = "__disabled__"
      "Cmd+Shift+S" = "__disabled__"

      # "Ctrl+F" = "hints"
      "Ctrl+F" = "recursive_grid --cursor-selection-mode hold"
      "Ctrl+S" = "scroll"

      # These keys dont have to be here, i didn't want to install another program to run these
      "Cmd+Alt+Shift+Ctrl+F" = "exec open -a \"Finder\""
      "Cmd+Alt+Shift+Ctrl+B" = "exec open -a \"Brave Browser\""
      # "Cmd+Alt+Shift+Ctrl+B" = "exec open -a \"Helium\""
      # "Cmd+Alt+Shift+Ctrl+B" = "exec open -a \"Safari\""
      "Cmd+Alt+Shift+Ctrl+T" = "exec open -a \"Ghostty\""
      "Cmd+Alt+Shift+Ctrl+N" = "exec open -a \"Notes\""
      "Cmd+Alt+Shift+Ctrl+R" = "exec open -a \"Reminders\""
      "Cmd+Alt+Shift+Ctrl+M" = "exec open -a \"Mail\""
      "Cmd+Alt+Shift+Ctrl+C" = "exec open -a \"Calendar\""
      "Cmd+Alt+Shift+Ctrl+W" = "exec open -a \"WhatsApp\""
      "Cmd+Alt+Shift+Ctrl+P" = "exec open -a \"Passwords\""
      "Cmd+Alt+Shift+Ctrl+S" = "exec open -a \"System Settings\""
      "Cmd+Alt+Shift+Ctrl+A" = "exec open -a \"Activity Monitor\""

      # "Alt+Shift+1" = "exec move-to-space 1"
      # "Alt+Shift+2" = "exec move-to-space 2"
      # "Alt+Shift+3" = "exec move-to-space 3"
      # "Alt+Shift+4" = "exec move-to-space 4"
      # "Alt+Shift+5" = "exec move-to-space 5"
      # "Alt+Shift+6" = "exec move-to-space 6"
      # "Alt+Shift+7" = "exec move-to-space 7"
      # "Alt+Shift+8" = "exec move-to-space 8"
      # "Alt+Shift+9" = "exec move-to-space 9"

      "Alt+H" = "exec yabai -m window --focus west"
      "Alt+J" = "exec yabai -m window --focus south"
      "Alt+K" = "exec yabai -m window --focus north"
      "Alt+L" = "exec yabai -m window --focus east"

      "Alt+Shift+H" = "exec yabai -m window --swap west"
      "Alt+Shift+J" = "exec yabai -m window --swap south"
      "Alt+Shift+K" = "exec yabai -m window --swap north"
      "Alt+Shift+L" = "exec yabai -m window --swap east"

      "Alt+M" = "exec yabai -m window --toggle zoom-fullscreen"
      "Alt+F" = "exec yabai -m window --toggle float; yabai -m window --grid 4:4:1:1:2:2"

      "Alt+Shift+1" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed cmd+shift+ctrl+alt+1", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "exec yabai -m space --balance", "action restore_cursor_pos"]
      "Alt+Shift+2" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed cmd+shift+ctrl+alt+2", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "exec yabai -m space --balance", "action restore_cursor_pos"]
      "Alt+Shift+3" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed cmd+shift+ctrl+alt+3", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "exec yabai -m space --balance", "action restore_cursor_pos"]
      "Alt+Shift+4" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed cmd+shift+ctrl+alt+4", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "exec yabai -m space --balance", "action restore_cursor_pos"]
      "Alt+Shift+5" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed cmd+shift+ctrl+alt+5", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "exec yabai -m space --balance", "action restore_cursor_pos"]
      "Alt+Shift+6" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed cmd+shift+ctrl+alt+6", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "exec yabai -m space --balance", "action restore_cursor_pos"]
      "Alt+Shift+7" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed cmd+shift+ctrl+alt+7", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "exec yabai -m space --balance", "action restore_cursor_pos"]
      "Alt+Shift+8" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed cmd+shift+ctrl+alt+8", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "exec yabai -m space --balance", "action restore_cursor_pos"]
      "Alt+Shift+9" = ["action save_cursor_pos", "action move_mouse --window --y -1000 --x -1000", "action sleep 0.05", "action move_mouse_relative --dx 100 --dy 2", "action sleep 0.05", "action mouse_down", "action sleep 0.1", "action move_mouse_relative --dx 5 --dy 5", "action sleep 0.1", "action feed cmd+shift+ctrl+alt+9", "action sleep 0.2", "action mouse_up", "action sleep 0.05", "exec yabai -m space --balance", "action restore_cursor_pos"]

      # ============================================================================
      # Hints
      # ============================================================================
      [hints]
      enabled = false
      hint_characters = "aoeuidhtns"
      include_menubar_hints = true
      include_dock_hints = true
      include_nc_hints = true
      include_stage_manager_hints = true
      detect_mission_control = true

      [hints.additional_ax_support]
      enable = true

      additional_electron_bundles = []
      additional_chromium_bundles = []
      additional_firefox_bundles = []

      [[hints.app_configs]]
      bundle_id = "com.brave.Browser"
      additional_clickable_roles = ["AXTabGroup"]
      ignore_clickable_check = false

      [hints.hotkeys]
      "Enter" = "action left_click"
      "Shift+Enter" = "action right_click"
      "Primary+Enter" = "action middle_click"
      "," = "hints"
      "Up" = "action move_mouse_relative --dx=0 --dy=-10"
      "Down" = "action move_mouse_relative --dx=0 --dy=10"
      "Left" = "action move_mouse_relative --dx=-10 --dy=0"
      "Right" = "action move_mouse_relative --dx=10 --dy=0"
      "Ctrl+J" = "action scroll_down"
      "Ctrl+K" = "action scroll_up"
      "Ctrl+H" = "action scroll_left"
      "Ctrl+L" = "action scroll_right"

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
      grid_cols = 3
      grid_rows = 3
      keys = "gcrhtnmwv"
      min_size_width = 10
      min_size_height = 10

      [recursive_grid.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"
      line_width = 1
      text_color = "#00000000"

      [recursive_grid.hotkeys]
      # disable defaults
      "Space" = "__disabled__"
      "Shift+L" = "__disabled__"
      "Shift+M" = "__disabled__"
      "Shift+I" = "__disabled__"
      "Shift+U" = "__disabled__"
      "Shift+R" = "__disabled__"
      "`" = "__disabled__"

      "Ctrl+C" = "idle"
      "," = "action reset"
      "s" = "scroll"
      "Tab" = "toggle-cursor-follow-selection"
      "'" = "action move_mouse --center"
      "i" = "action move_mouse"
      "u" = "action left_click"
      "e" = "action middle_click"
      "o" = "action right_click"
      "." = "action mouse_down"
      "p" = "action mouse_up"
      "Ctrl+J" = "action scroll_down"
      "Ctrl+K" = "action scroll_up"
      "Ctrl+H" = "action scroll_left"
      "Ctrl+L" = "action scroll_right"

      [[recursive_grid.app_configs]]
      bundle_id = "com.brave.Browser"
      hotkeys = {
        "1" = ["action right_click", "action sleep 0.1", "action feed o p e n enter m d a enter"],
        "2" = ["action right_click", "action sleep 0.1", "action feed o p e n enter s k b enter"],
        "3" = ["action right_click", "action sleep 0.1", "action feed o p e n enter t r a enter"],
        "4" = ["action right_click", "action sleep 0.1", "action feed o p e n enter m a d enter"],
        "5" = ["action right_click", "action sleep 0.1", "action feed o p e n enter w a k enter"],
      }

      # ============================================================================
      # Scroll
      # ============================================================================

      [scroll]
      scroll_step = 150

      [scroll.hotkeys]
      # disable defaults
      "Shift+L" = "__disabled__"
      "Shift+M" = "__disabled__"
      "Shift+I" = "__disabled__"
      "Shift+U" = "__disabled__"
      "Shift+R" = "__disabled__"

      "Ctrl+C" = "idle"
      "s" = "recursive_grid --cursor-selection-mode hold"
      "'" = "action move_mouse --center"

      [smooth_scroll]
      enabled = true
      steps = 100
      max_duration = 100
      duration_per_pixel = 5.00

      [mouse_action_indicator]
      enabled = true

      # ============================================================================
      # Mode Indicator
      # ============================================================================
      [mode_indicator.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"
    '';
  };
}
