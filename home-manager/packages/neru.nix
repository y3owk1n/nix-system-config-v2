{ pkgs, ... }:
{
  # ============================================================================
  # Neru - Vimium-like Browser Extension
  # ============================================================================
  # System-wide vimium extension for mouse and keyboard control

  services.neru = {
    enable = true;
    package = pkgs.neru-source;
    config = ''
      # ============================================================================
      # General Settings
      # ============================================================================
      [general]
      restore_cursor_position = true

      # ============================================================================
      # Hotkeys
      # ============================================================================
      [hotkeys]
      "Ctrl+F" = "grid -a left_click"  # Grid navigation with auto-click
      "Ctrl+G" = "grid"               # Grid navigation
      "Ctrl+S" = "scroll"             # Scroll mode

      # ============================================================================
      # Hints (Link following)
      # ============================================================================
      [hints]
      enabled = false  # Disabled in favor of grid navigation

      # ============================================================================
      # Grid Navigation
      # ============================================================================
      [grid]
      font_family = "DejaVuSansMono-Bold"
      characters = "aoeuidhtnspyfgcrlqjkxbmwvz"  # Dvorak-optimized character set
      sublayer_keys = "gcrhtnmwv"

      [action]
      left_click_key = "h"
      middle_click_key = "t"
      right_click_key = "n"
      mouse_down_key = "c"
      mouse_up_key = "r"

      # ============================================================================
      # Smooth Cursor Movement
      # ============================================================================
      [smooth_cursor]
      move_mouse_enabled = true
      steps = 10
      delay = 1

      # ============================================================================
      # Logging
      # ============================================================================
      [logging]
      log_level = "info"
      disable_file_logging = true
    '';
  };
}
