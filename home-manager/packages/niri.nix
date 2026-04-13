{ config, ... }:
{
  ##############################################
  # Disable Stylix's niri target to avoid conflict
  stylix.targets.niri.enable = false;

  ##############################################
  # Niri config with Stylix colors
  xdg.configFile."niri/config.kdl".text = ''
    input {
      keyboard { xkb { layout "us"; } }
      touchpad {
        tap
        natural-scroll
        accel-speed 0.2
      }
    }

    output "eDP-1" {
      scale 1.0
    }

    layout {
      gaps 8
      center-focused-column "never"
      preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
      }
      default-column-width { proportion 0.5; }
      focus-ring {
        width 2
        active-color   "#${config.lib.stylix.colors.base0D}"
        inactive-color "#${config.lib.stylix.colors.base03}"
      }
      border { off; }
    }

    spawn-at-startup "waybar"
    spawn-at-startup "mako"
    spawn-at-startup "nm-applet" "--indicator"
    spawn-at-startup "swayidle" "-w"
      "timeout" "300" "swaylock -f"
      "timeout" "600" "niri msg action power-off-monitors"
      "before-sleep" "swaylock -f"

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/Screenshot_%Y-%m-%d_%H-%M-%S.png"

    binds {
      Mod+Return  { spawn "ghostty"; }
      Mod+D       { spawn "fuzzel"; }
      Mod+Q       { close-window; }
      Mod+Shift+E { quit; }

      Mod+Left        { focus-column-left; }
      Mod+Right       { focus-column-right; }
      Mod+Up          { focus-window-up; }
      Mod+Down        { focus-window-down; }
      Mod+Shift+Left  { move-column-left; }
      Mod+Shift+Right { move-column-right; }

      Mod+1 { focus-workspace 1; }
      Mod+2 { focus-workspace 2; }
      Mod+3 { focus-workspace 3; }
      Mod+4 { focus-workspace 4; }
      Mod+5 { focus-workspace 5; }
      Mod+Shift+1 { move-window-to-workspace 1; }
      Mod+Shift+2 { move-window-to-workspace 2; }
      Mod+Shift+3 { move-window-to-workspace 3; }
      Mod+Shift+4 { move-window-to-workspace 4; }
      Mod+Shift+5 { move-window-to-workspace 5; }

      Mod+Minus       { set-column-width "-10%"; }
      Mod+Equal       { set-column-width "+10%"; }
      Mod+Shift+Minus { set-window-height "-10%"; }
      Mod+Shift+Equal { set-window-height "+10%"; }
      Mod+F           { maximize-column; }
      Mod+Shift+F     { fullscreen-window; }
      Mod+C           { center-column; }

      Print       { screenshot; }
      Shift+Print { screenshot-screen; }

      XF86AudioRaiseVolume  { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
      XF86AudioLowerVolume  { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
      XF86AudioMute         { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
      XF86MonBrightnessUp   { spawn "brightnessctl" "set" "5%+"; }
      XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }
    }

    window-rule {
      match app-id="org.gnome.Nautilus"
      open-floating true
      default-floating-size { width 900; height 600; }
    }

    window-rule {
      match app-id="pavucontrol"
      open-floating true
      default-floating-size { width 700; height 500; }
    }
  '';

  ##############################################
  # Waybar — structure only, Stylix injects colors
  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "layer": "top",
      "position": "top",
      "height": 32,
      "spacing": 4,
      "modules-left":   ["niri/workspaces", "niri/window"],
      "modules-center": ["clock"],
      "modules-right":  ["pulseaudio", "network", "battery", "tray"],
      "clock": {
        "format": "{:%a %b %d  %H:%M}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
      },
      "battery": {
        "states": { "warning": 30, "critical": 15 },
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
      },
      "network": {
        "format-wifi": "{essid} ",
        "format-ethernet": "{ipaddr} ",
        "format-disconnected": "disconnected"
      },
      "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "muted ",
        "format-icons": { "default": ["", "", ""] }
      },
      "tray": { "spacing": 8 }
    }
  '';

  ##############################################
  # Mako (notifications)
  services.mako = {
    enable = true;
    defaultTimeout = 5000;
    borderRadius = 8;
    borderSize = 1;
    padding = "12,16";
  };
}
