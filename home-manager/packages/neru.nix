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
      "Ctrl+F" = "grid"               # Grid navigation
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
      font_family = "JetBrainsMonoNLNFP-Bold"
      characters = "aoeuidhtnspyfgcrlqjkxbmwvz"  # Dvorak-optimized character set
      sublayer_keys = "gcrhtnmwv"

      [action]
      [action.key_bindings]
      left_click = "Shift+H"
      middle_click = "Shift+T"
      right_click = "Shift+N"
      mouse_down = "Shift+R"
      mouse_up = "Shift+C"

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
