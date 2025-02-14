{ pkgs, ... }:
{
  services = {
    yabai = {
      enable = true;
      package = (
        pkgs.yabai.overrideAttrs (o: rec {
          version = "7.1.9";
          src = builtins.fetchTarball {
            url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
            sha256 = "sha256:0wvrgn44pdiypafmz2rw5bi5rq549c5y9c6lbpyrp5k2sbmpd5f7";
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
  };
}
