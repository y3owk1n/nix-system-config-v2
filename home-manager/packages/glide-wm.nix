_: {
  # ============================================================================
  # Glide Window Manager Configuration
  # ============================================================================
  # Custom tiling window manager for macOS with vim-like keybindings

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
