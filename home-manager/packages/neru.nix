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
    # package = pkgs.neru-source.overrideAttrs (_: {
    #   postPatch = ''
    #     substituteInPlace go.mod \
    #       --replace-fail "go 1.26.0" "go 1.25.7"
    #
    #     # Verify it worked
    #     echo "=== go.mod after patch ==="
    #     grep "^go " go.mod || true
    #   '';
    # });
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

      "Ctrl+F" = "recursive_grid --cursor-selection-mode hold"
      "Ctrl+S" = "scroll"

      # These keys dont have to be here, i didn't want to install another program to run these
      "Cmd+Alt+Shift+Ctrl+F" = "exec open -a \"Finder\""
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

      "Alt+Shift+1" = "exec move-to-space 1; yabai -m space --balance"
      "Alt+Shift+2" = "exec move-to-space 2; yabai -m space --balance"
      "Alt+Shift+3" = "exec move-to-space 3; yabai -m space --balance"
      "Alt+Shift+4" = "exec move-to-space 4; yabai -m space --balance"
      "Alt+Shift+5" = "exec move-to-space 5; yabai -m space --balance"
      "Alt+Shift+6" = "exec move-to-space 6; yabai -m space --balance"
      "Alt+Shift+7" = "exec move-to-space 7; yabai -m space --balance"
      "Alt+Shift+8" = "exec move-to-space 8; yabai -m space --balance"
      "Alt+Shift+9" = "exec move-to-space 9; yabai -m space --balance"

      # ============================================================================
      # Hints
      # ============================================================================
      [hints]
      enabled = false

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
      grid_rows = 6
      keys = "',.pyaoeui;qjkxfgcrldhtnsbmwvz"
      # min_size_width = 10
      # min_size_height = 10

      [[recursive_grid.layers]]
      depth = 2
      grid_cols = 4
      grid_rows = 2
      keys = "htnsmwvz"

      [recursive_grid.animation]
      enabled = true
      duration_ms = 180

      [recursive_grid.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"
      line_width = 1
      label_background = true
      sub_key_preview = true
      # text_color = "#00000000"

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
      "=" = "action reset"
      # "s" = "scroll"
      "Tab" = "toggle-cursor-follow-selection"
      "-" = "action move_mouse --center"
      "/" = "action move_mouse --selection"
      "Enter" = "action left_click"
      "Cmd+Enter" = "action middle_click"
      "Alt+Enter" = "action right_click"
      "1" = "action mouse_down"
      "2" = "action mouse_up"
      "Ctrl+J" = "action scroll_down"
      "Ctrl+K" = "action scroll_up"
      "Ctrl+H" = "action scroll_left"
      "Ctrl+L" = "action scroll_right"

      # ============================================================================
      # Scroll
      # ============================================================================

      [scroll]

      [scroll.hotkeys]
      # disable defaults
      "Shift+L" = "__disabled__"
      "Shift+M" = "__disabled__"
      "Shift+I" = "__disabled__"
      "Shift+U" = "__disabled__"
      "Shift+R" = "__disabled__"

      "Ctrl+C" = "idle"
      "'" = "action move_mouse --center"

      # ============================================================================
      # Mode Indicator
      # ============================================================================
      [mode_indicator.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"

      # ============================================================================
      # Smooth Cursor Movement
      # ============================================================================
      [smooth_cursor]
      move_mouse_enabled = true
      steps = 100
      max_duration = 50
    '';
  };
}
