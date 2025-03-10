{ pkgs, ... }:
{
  services = {
    yabai = {
      enable = true;
      package = (
        pkgs.yabai.overrideAttrs (o: rec {
          version = "7.1.11";
          src = builtins.fetchTarball {
            url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
            sha256 = "sha256:041jg8d990wgzf5mgr3q9zi6hysfs8azcshs9flj3dm8w0d1aajv";
          };
        })
      );
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
        top_padding = 10;
        bottom_padding = 10;
        left_padding = 10;
        right_padding = 10;
        window_gap = 10;
      };

      extraConfig = ''
        # apps to not manage (ignore)
        yabai -m rule --add app="^(Finder|System Settings|Archive Utility|Creative Cloud|Logi Options|FaceTime)$" manage=off
      '';
    };
    skhd = {
      enable = true;
      package = pkgs.skhd;
      skhdConfig = ''
        cmd + shift + alt + ctrl - h : yabai -m window --focus west
        cmd + shift + alt + ctrl - j : yabai -m window --focus south
        cmd + shift + alt + ctrl - k : yabai -m window --focus north
        cmd + shift + alt + ctrl - l : yabai -m window --focus east

        # swap managed window
        ctrl + shift - h : yabai -m window --swap west
        ctrl + shift - j : yabai -m window --swap south
        ctrl + shift - k : yabai -m window --swap north
        ctrl + shift - l : yabai -m window --swap east

        # rotate layout clockwise
        cmd + shift + alt + ctrl - r : yabai -m space --rotate 270

        # toggle window fullscreen zoom
        cmd + shift + alt + ctrl - m : yabai -m window --toggle zoom-fullscreen

        # float / unfloat window and center on screen
        cmd + shift + alt + ctrl - t : yabai -m window --toggle float;\
        			yabai -m window --grid 4:4:1:1:2:2

        # balance size of windows
        cmd + shift + alt + ctrl - 0 : yabai -m space --balance
      '';
    };
  };
}
