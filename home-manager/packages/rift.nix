_: {
  # ============================================================================
  # Rift Window Manager Configuration
  # ============================================================================
  # Custom tiling window manager for macOS with vim-like keybindings

  services.rift = {
    enable = true;
    config = ''
      # ============================================================================
      # General Settings
      # ============================================================================
      [settings]
      default_disable = false
      hot_reload = false

      # ============================================================================
      # Layout Configuration
      # ============================================================================
      [settings.layout]
      mode = "traditional"
      # mode = "bsp"  # Alternative: binary space partitioning

      [settings.layout.gaps]

      [settings.layout.gaps.outer]
      top = 8
      left = 8
      bottom = 8
      right = 8

      [settings.layout.gaps.inner]
      horizontal = 8
      vertical = 8

      # ============================================================================
      # UI Configuration
      # ============================================================================
      [settings.ui.menu_bar]
      enabled = true
      show_empty = false
      display_style = "label"
      mode = "active"

      # ============================================================================
      # Virtual Workspaces
      # ============================================================================
      [virtual_workspaces]
      default_workspace_count = 9
      default_workspace = 0

      workspace_names = [
      	"browser",
         "terminal",
         "notes",
         "email",
         "calendar",
         "messaging",
         "design",
         "screen sharing",
         "dumpster"
       ]

      # ============================================================================
      # Application Rules
      # ============================================================================
      # Automatically assign applications to specific workspaces
      app_rules = [
        { app_id = "com.apple.Safari", workspace = "browser" },
        { app_id = "com.apple.SafariTechnologyPreview", workspace = "browser" },
        { app_id = "net.imput.helium", workspace = "browser" },
        { app_id = "org.mozilla.firefox", workspace = "browser" },
        { app_id = "app.zen-browser.zen", workspace = "browser" },
        { app_id = "com.mitchellh.ghostty", workspace = "terminal" },
        { app_id = "com.apple.Terminal", workspace = "terminal" },
        { app_id = "com.apple.Notes", workspace = "notes" },
        { app_id = "net.whatsapp.WhatsApp", workspace = "messaging" },
        { app_id = "com.apple.MobileSMS", workspace = "messaging" },
        { app_id = "com.apple.mail", workspace = "email" },
        { app_id = "com.apple.iCal", workspace = "calendar" },
        { app_id = "com.adobe.Photoshop", workspace = "design" },
        { app_id = "com.adobe.illustrator", workspace = "design" },
        { app_id = "org.blenderfoundation.blender", workspace = "design" },
        { app_id = "com.apple.ScreenSharing", workspace = "screen sharing" },
        { app_id = "com.carriez.rustdesk", workspace = "screen sharing" },
        { app_id = "com.apple.systempreferences", floating = true }
      ]

      # ============================================================================
      # Keybindings
      # ============================================================================
      [modifier_combinations]
      comb1 = "Alt + Shift"
      hyper = "Alt + Ctrl + Shift + Meta"

      [keys]
      # App launchers (hyper key)
      "hyper + F" = { exec = ["open", "-a", "finder"] }
      "hyper + B" = { exec = ["open", "-a", "safari"] }
      "hyper + T" = { exec = ["open", "-a", "Ghostty"] }
      "hyper + N" = { exec = ["open", "-a", "Notes"] }
      "hyper + M" = { exec = ["open", "-a", "Mail"] }
      "hyper + C" = { exec = ["open", "-a", "Calendar"] }
      "hyper + W" = { exec = ["open", "-a", "WhatsApp"] }
      "hyper + S" = { exec = ["open", "-a", "System Preferences"] }
      "hyper + P" = { exec = ["open", "-a", "Passwords"] }
      "hyper + A" = { exec = ["open", "-a", "Activity Monitor"] }

      # Vim-style focus navigation (hjkl)
      "Alt + H" = { move_focus = "left" }
      "Alt + J" = { move_focus = "down" }
      "Alt + K" = { move_focus = "up" }
      "Alt + L" = { move_focus = "right" }

      # Vim-style window movement
      "comb1 + H" = { move_node = "left" }
      "comb1 + J" = { move_node = "down" }
      "comb1 + K" = { move_node = "up" }
      "comb1 + L" = { move_node = "right" }

      # Workspace switching (hyper + number)
      "hyper + 1" = { switch_to_workspace = "browser" }
      "hyper + 2" = { switch_to_workspace = "terminal" }
      "hyper + 3" = { switch_to_workspace = "notes" }
      "hyper + 4" = { switch_to_workspace = "email" }
      "hyper + 5" = { switch_to_workspace = "calendar" }
      "hyper + 6" = { switch_to_workspace = "messaging" }
      "hyper + 7" = { switch_to_workspace = "design" }
      "hyper + 8" = { switch_to_workspace = "screen sharing" }
      "hyper + 9" = { switch_to_workspace = "dumpster" }

      # Move windows to workspaces (alt-shift + number)
      "comb1 + 1" = { move_window_to_workspace = "browser" }
      "comb1 + 2" = { move_window_to_workspace = "terminal" }
      "comb1 + 3" = { move_window_to_workspace = "notes" }
      "comb1 + 4" = { move_window_to_workspace = "email" }
      "comb1 + 5" = { move_window_to_workspace = "calendar" }
      "comb1 + 6" = { move_window_to_workspace = "messaging" }
      "comb1 + 7" = { move_window_to_workspace = "design" }
      "comb1 + 8" = { move_window_to_workspace = "screen sharing" }
      "comb1 + 9" = { move_window_to_workspace = "dumpster" }

      # Window management
      "Alt + F" = "toggle_window_floating"
      "Alt + M" = "toggle_fullscreen_within_gaps"

      # Window resizing
      "Alt + Equal" = "resize_window_grow"
      "Alt + Minus" = "resize_window_shrink"
    '';
  };
}
