{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    hyprland
    waybar
    wlogout
    rofi
    swaylock
    swaynotificationcenter
    wl-clipboard
    wl-clipboard-x11
    grim
    slurp
    hyprpaper
    hyprcursor
    hypridle
    hyprlock
    polkit_gnome
    xdg-desktop-portal-hyprland
    xdg-utils
    networkmanagerapplet
    blueman
    brightnessctl
    pamixer
    playerctl
    libnotify # For desktop notifications
    xfce.thunar # XFCE file manager, works well with Hyprland
    xfce.thunar-volman # For automounting drives
    xfce.thunar-archive-plugin # Archive management
    file-roller # Archive manager
  ];

  programs.rofi = {
    enable = true;
    location = "center";
    terminal = "ghostty";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$menu" = "rofi -show drun";
      "$browser" = "firefox";

      # Monitor configuration for VMware - auto-detect
      monitor = ",preferred,auto,1";

      # Basic environment setup
      env = [
        "XCURSOR_SIZE,24"
        "QT_QPA_PLATFORMTHEME,qt6ct"
      ];

      # Input configuration
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";

        follow_mouse = 1;

        touchpad = {
          natural_scroll = false;
        };

        sensitivity = 0;
      };

      # General configuration
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        layout = "dwindle";
        allow_tearing = false;
      };

      # Decoration settings (simplified for better compatibility)
      decoration = {
        rounding = 10;

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };

        shadow = {
          enabled = false;
          ignore_window = false;
          offset = "0, -4";
          range = 4;
          render_power = 3;
        };
      };

      # Animations (re-enabled, but faster for VMware)
      animations = {
        enabled = true;

        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

        animation = [
          "windows, 1, 3, myBezier"
          "windowsOut, 1, 3, default"
          "border, 1, 5, default"
          "fade, 1, 3, default"
          "workspaces, 1, 3, default"
        ];
      };

      # Dwindle layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
      };

      # Keybindings
      bind = [
        # Apps
        "$mod SHIFT CTRL ALT, T, exec, $terminal --gtk-single-instance=true"
        "$mod, Space, exec, $menu"
        "$mod SHIFT CTRL ALT, B, exec, $browser"
        "$mod SHIFT CTRL ALT, F, exec, thunar"

        # Window management
        "$mod, Q, killactive"
        "ALT, M, fullscreen, 0"
        "ALT, F, togglefloating"

        # Move focus
        "ALT, h, movefocus, l"
        "ALT, l, movefocus, r"
        "ALT, k, movefocus, u"
        "ALT, j, movefocus, d"

        # Move windows
        "ALT SHIFT, h, movewindow, l"
        "ALT SHIFT, l, movewindow, r"
        "ALT SHIFT, k, movewindow, u"
        "ALT SHIFT, j, movewindow, d"

        # Workspaces
        "$mod SHIFT CTRL ALT, 1, workspace, 1"
        "$mod SHIFT CTRL ALT, 2, workspace, 2"
        "$mod SHIFT CTRL ALT, 3, workspace, 3"
        "$mod SHIFT CTRL ALT, 4, workspace, 4"
        "$mod SHIFT CTRL ALT, 5, workspace, 5"
        "$mod SHIFT CTRL ALT, 6, workspace, 6"
        "$mod SHIFT CTRL ALT, 7, workspace, 7"
        "$mod SHIFT CTRL ALT, 8, workspace, 8"
        "$mod SHIFT CTRL ALT, 9, workspace, 9"
        "$mod SHIFT CTRL ALT, 0, workspace, 10"

        # Move to workspace
        "ALT SHIFT, 1, movetoworkspace, 1"
        "ALT SHIFT, 2, movetoworkspace, 2"
        "ALT SHIFT, 3, movetoworkspace, 3"
        "ALT SHIFT, 4, movetoworkspace, 4"
        "ALT SHIFT, 5, movetoworkspace, 5"
        "ALT SHIFT, 6, movetoworkspace, 6"
        "ALT SHIFT, 7, movetoworkspace, 7"
        "ALT SHIFT, 8, movetoworkspace, 8"
        "ALT SHIFT, 9, movetoworkspace, 9"
        "ALT SHIFT, 0, movetoworkspace, 10"

        # Media keys
        ", XF86AudioRaiseVolume, exec, pamixer -i 5"
        ", XF86AudioLowerVolume, exec, pamixer -d 5"
        ", XF86AudioMute, exec, pamixer -t"
        ", XF86MonBrightnessUp, exec, brightnessctl s +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl s 5%-"

        # Screenshot
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"

        # System
        "$mod, Escape, exec, wlogout"
        "$mod SHIFT, R, exec, hyprctl reload"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Window rules
      windowrulev2 = [
        "float, class:^(pavucontrol)$"
        "float, class:^(blueman-manager)$"
        "float, class:^(nm-connection-editor)$"
        "size 800 600, class:^(pavucontrol)$"
        "size 800 600, class:^(nm-connection-editor)$"
        # Keep terminal windows on workspace 1 and focused
        "workspace 1 silent, class:^(ghostty)$"
      ];

      # Startup applications (minimal to avoid issues)
      exec-once = [
        "notify-send 'Hyprland Ready' 'Hyprland is ready! Mod4+Return for terminal'"
        "waybar"
        "swaync"
        "/etc/profiles/per-user/kylewong/bin/nm-applet --indicator"
      ];
    };
  };

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        output = [ "*" ];
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "cpu"
          "memory"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };

        clock = {
          format = "{:%H:%M}";
          tooltip-format = "{:%Y-%m-%d | %H:%M}";
        };

        cpu = {
          format = "CPU {usage}%";
          interval = 2;
        };

        memory = {
          format = "MEM {}%";
          interval = 2;
        };

        tray = {
          spacing = 10;
        };
      };
    };

    style = ''
      * {
        font-family: "JetBrains Mono", monospace;
        font-size: 13px;
      }

      window#waybar {
        background-color: rgba(43, 48, 59, 0.95);
        border-bottom: 3px solid rgba(100, 114, 125, 0.5);
        color: #ffffff;
        transition-property: background-color;
        transition-duration: .5s;
      }

      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #ffffff;
        border-radius: 0;
      }

      #workspaces button.active {
        background-color: #64727D;
        box-shadow: inset 0 -3px #ffffff;
      }

      #clock, #cpu, #memory {
        padding: 0 10px;
      }
    '';
  };

  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-width = 400;
      notification-window-width = 400;
    };
  };

  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    # Software rendering for VMs
    WLR_RENDERER = "pixman";
    LIBGL_ALWAYS_SOFTWARE = "1";
    EGL_PLATFORM = "wayland";
  };

  xdg.configFile."wlogout/layout" = {
    text = ''
      {
        "label" : "lock",
        "action" : "hyprlock",
        "text" : "Lock",
        "keybind" : "l"
      }
      {
        "label" : "hibernate",
        "action" : "systemctl hibernate",
        "text" : "Hibernate",
        "keybind" : "h"
      }
      {
        "label" : "logout",
        "action" : "loginctl terminate-session $XDG_SESSION_ID",
        "text" : "Logout",
        "keybind" : "e"
      }
      {
        "label" : "shutdown",
        "action" : "systemctl poweroff",
        "text" : "Shutdown",
        "keybind" : "s"
      }
      {
        "label" : "suspend",
        "action" : "systemctl suspend",
        "text" : "Suspend",
        "keybind" : "u"
      }
      {
        "label" : "reboot",
        "action" : "systemctl reboot",
        "text" : "Reboot",
        "keybind" : "r"
      }
    '';
  };

  xdg.configFile."hyprpaper/hyprpaper.conf".text = ''
    preload = /usr/share/backgrounds/default.png
    wallpaper = ,/usr/share/backgrounds/default.png
  '';
}
