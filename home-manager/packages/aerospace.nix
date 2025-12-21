_: {
  # ============================================================================
  # Aerospace Window Manager Configuration
  # ============================================================================
  # Tiling window manager for macOS with vim-like keybindings
  # Currently disabled in favor of Rift

  programs.aerospace = {
    enable = true;
    extraConfig = ''
      # ============================================================================
      # Basic Configuration
      # ============================================================================
      config-version = 2

      # Default layout settings
      default-root-container-layout = 'tiles'
      default-root-container-orientation = 'auto'

      # Container normalization settings
      enable-normalization-flatten-containers = true
      enable-normalization-opposite-orientation-for-nested-containers = true

      # Mouse behavior
      on-focused-monitor-changed = ['move-mouse monitor-lazy-center']
      on-focus-changed = ["move-mouse window-force-center"]

      # Persistent workspaces (1-9)
      persistent-workspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

      automatically-unhide-macos-hidden-apps = false

      # ============================================================================
      # Window Gaps
      # ============================================================================
      [gaps]
      inner.horizontal = 8
      inner.vertical = 8
      outer.left = 8
      outer.bottom = 8
      outer.top = 8
      outer.right = 8

      # ============================================================================
      # Keybindings
      # ============================================================================
      [mode.main.binding]
      # Disable default macOS shortcuts that conflict
      cmd-h = []     # Disable "hide application"
      cmd-alt-h = [] # Disable "hide others"
      cmd-m = [] # Disable "minimize"

      # Vim-style focus navigation (hjkl)
      alt-h = 'focus left'
      alt-j = 'focus down'
      alt-k = 'focus up'
      alt-l = 'focus right'

      # Vim-style window movement
      alt-shift-h = 'move left'
      alt-shift-j = 'move down'
      alt-shift-k = 'move up'
      alt-shift-l = 'move right'

      # Toggle floating/tiling layout
      alt-f = 'layout floating tiling'

      # Toggle fullscreen
      alt-m = 'fullscreen'

      # App launchers (hyper key combinations)
      cmd-alt-shift-ctrl-f = 'exec-and-forget open -a "Finder"'
      cmd-alt-shift-ctrl-b = 'exec-and-forget open -a "Helium"'
      cmd-alt-shift-ctrl-t = 'exec-and-forget open -a "Ghostty"'
      cmd-alt-shift-ctrl-n = 'exec-and-forget open -a "Notes"'
      cmd-alt-shift-ctrl-m = 'exec-and-forget open -a "Mail"'
      cmd-alt-shift-ctrl-c = 'exec-and-forget open -a "Calendar"'
      cmd-alt-shift-ctrl-w = 'exec-and-forget open -a "WhatsApp"'
      cmd-alt-shift-ctrl-s = 'exec-and-forget open -a "System Preferences"'
      cmd-alt-shift-ctrl-p = 'exec-and-forget open -a "Passwords"'
      cmd-alt-shift-ctrl-a = 'exec-and-forget open -a "Activity Monitor"'

      # Workspace switching (hyper + number)
      cmd-alt-shift-ctrl-1 = 'workspace 1' # Browser
      cmd-alt-shift-ctrl-2 = 'workspace 2' # Terminal
      cmd-alt-shift-ctrl-3 = 'workspace 3' # Notes
      cmd-alt-shift-ctrl-4 = 'workspace 4' # Email
      cmd-alt-shift-ctrl-5 = 'workspace 5' # Calendar
      cmd-alt-shift-ctrl-6 = 'workspace 6' # Messaging
      cmd-alt-shift-ctrl-7 = 'workspace 7' # Design
      cmd-alt-shift-ctrl-8 = 'workspace 8' # Screen sharing
      cmd-alt-shift-ctrl-9 = 'workspace 9' # Whatever else goes here
      cmd-alt-shift-ctrl-0 = 'flatten-workspace-tree'

      # Move windows to workspaces (alt-shift + number)
      alt-shift-1 = ['move-node-to-workspace 1', 'workspace 1']
      alt-shift-2 = ['move-node-to-workspace 2', 'workspace 2']
      alt-shift-3 = ['move-node-to-workspace 3', 'workspace 3']
      alt-shift-4 = ['move-node-to-workspace 4', 'workspace 4']
      alt-shift-5 = ['move-node-to-workspace 5', 'workspace 5']
      alt-shift-6 = ['move-node-to-workspace 6', 'workspace 6']
      alt-shift-7 = ['move-node-to-workspace 7', 'workspace 7']
      alt-shift-8 = ['move-node-to-workspace 8', 'workspace 8']
      alt-shift-9 = ['move-node-to-workspace 9', 'workspace 9']

      # ============================================================================
      # Application Rules
      # ============================================================================
      # Automatically assign applications to specific workspaces

      [[on-window-detected]]
      if.app-id = 'com.apple.Safari'
      run = 'move-node-to-workspace 1'

      [[on-window-detected]]
      if.app-id = 'com.apple.SafariTechnologyPreview'
      run = 'move-node-to-workspace 1'

      [[on-window-detected]]
      if.app-id = 'net.imput.helium'
      run = 'move-node-to-workspace 1'

      [[on-window-detected]]
      if.app-id = 'org.mozilla.firefox'
      run = 'move-node-to-workspace 1'

      [[on-window-detected]]
      if.app-id = 'app.zen-browser.zen'
      run = 'move-node-to-workspace 1'

      [[on-window-detected]]
      if.app-id = 'com.mitchellh.ghostty'
      run = 'move-node-to-workspace 2'

      [[on-window-detected]]
      if.app-id = 'com.apple.Terminal'
      run = 'move-node-to-workspace 2'

      [[on-window-detected]]
      if.app-id = 'com.apple.Notes'
      run = 'move-node-to-workspace 3'

      [[on-window-detected]]
      if.app-id = 'net.whatsapp.WhatsApp'
      run = 'move-node-to-workspace 6'

      [[on-window-detected]]
      if.app-id = 'com.apple.MobileSMS'
      run = 'move-node-to-workspace 6'

      [[on-window-detected]]
      if.app-id = 'com.apple.mail'
      run = 'move-node-to-workspace 4'

      [[on-window-detected]]
      if.app-id = 'com.apple.iCal'
      run = 'move-node-to-workspace 5'

      [[on-window-detected]]
      if.app-id = 'com.adobe.Photoshop'
      run = 'move-node-to-workspace 7'

      [[on-window-detected]]
      if.app-id = 'com.adobe.illustrator'
      run = 'move-node-to-workspace 7'

      [[on-window-detected]]
      if.app-id = 'org.blenderfoundation.blender'
      run = 'move-node-to-workspace 7'

      [[on-window-detected]]
      if.app-id = 'com.apple.ScreenSharing'
      run = 'move-node-to-workspace 8'

      [[on-window-detected]]
      if.app-id = 'com.carriez.rustdesk'
      run = 'move-node-to-workspace 8'

      [[on-window-detected]]
      if.app-id = 'com.apple.systempreferences'
      run = ['layout floating']
    '';
    launchd = {
      enable = true;
    };
  };
}
