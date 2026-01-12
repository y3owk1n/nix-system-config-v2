_: {
  # homebrew = {
  #   casks = [ "spaceid" ];
  # };

  services = {
    yabai = {
      enable = false;
      config = {
        mouse_follows_focus = "on";
        focus_follows_mouse = "off";
        window_origin_display = "default";
        window_placement = "second_child"; # first_child, second_child
        window_zoom_persist = "on";
        window_shadow = "on";
        window_opacity = "on";
        window_opacity_duration = 0.15;
        window_animation_duration = 0.15;
        active_window_opacity = 1.0;
        normal_window_opacity = 0.85;
        split_ratio = 0.5;
        split_type = "auto";
        auto_balance = "off";
        mouse_modifier = "ctrl";
        mouse_action1 = "move";
        mouse_action2 = "resize";
        mouse_drop_action = "swap";
        layout = "bsp"; # stack, bsp, float
        top_padding = 8;
        bottom_padding = 8;
        left_padding = 8;
        right_padding = 8;
        window_gap = 8;
      };

      extraConfig = ''
        # apps to not manage (ignore)
        yabai -m rule --add app="^(Finder|System Settings|Archive Utility|Creative Cloud|Logi Options|FaceTime)$" manage=off
      '';
    };
  };
}
