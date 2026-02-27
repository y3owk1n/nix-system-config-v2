_: {
  # ============================================================================
  # Yabai Window Manager Configuration
  # ============================================================================
  # Custom tiling window manager for macOS

  services.yabai = {
    enable = true;
    config = ''
      # by default, tile all windows
      yabai -m config layout bsp

      # New window spawns to the right if vertical split, or bottom if horizontal split
      yabai -m config window_placement second_child

      # padding
      yabai -m config top_padding 8
      yabai -m config bottom_padding 8
      yabai -m config left_padding 8
      yabai -m config right_padding 8
      yabai -m config window_gap 8

      # mouse settings
      yabai -m config mouse_follows_focus on

      yabai -m config mouse_modifier ctrl
      # set modifier + left-click drag to move window (default: move)
      yabai -m config mouse_action1 move
      # set modifier + right-click drag to resize window (default: resize)
      yabai -m config mouse_action2 resize

      yabai -m mouse_drop_action swap

      yabai -m rule --add app="^(Finder|System Settings|Archive Utility|Creative Cloud|Logi Options|FaceTime)$" manage=off
    '';
  };
}
