{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aerospace;

  configFile = pkgs.writeScript "aerospace.toml" cfg.config;
in

{
  options = {
    aerospace = with lib.types; {
      enable = lib.mkEnableOption "AeroSpace window manager";

      package = lib.mkPackageOption pkgs "aerospace" { };

      config = lib.mkOption {
        type = types.lines;
        default = ''
          start-at-login = false
          after-login-command = []

          default-root-container-layout = 'tiles'
          default-root-container-orientation = 'auto'

          enable-normalization-flatten-containers = true
          enable-normalization-opposite-orientation-for-nested-containers = true

          on-focused-monitor-changed = ['move-mouse monitor-lazy-center']
          on-focus-changed = ["move-mouse window-force-center"]

          automatically-unhide-macos-hidden-apps = false

          [gaps]
          inner.horizontal = 8
          inner.vertical = 8
          outer.left = 8
          outer.bottom = 8
          outer.top = 8
          outer.right = 8

          [mode.main.binding]
          cmd-h = []     # Disable "hide application"
          cmd-alt-h = [] # Disable "hide others"

          alt-h = 'focus left'
          alt-j = 'focus down'
          alt-k = 'focus up'
          alt-l = 'focus right'

          alt-shift-h = 'move left'
          alt-shift-j = 'move down'
          alt-shift-k = 'move up'
          alt-shift-l = 'move right'

          alt-f = 'layout floating tiling'

          alt-m = 'fullscreen'

          cmd-alt-shift-ctrl-f = 'exec-and-forget open -a finder'
          cmd-alt-shift-ctrl-b = 'exec-and-forget open -a "Helium"'
          cmd-alt-shift-ctrl-t = 'exec-and-forget open -a "Ghostty"'
          cmd-alt-shift-ctrl-n = 'exec-and-forget open -a "Notes"'
          cmd-alt-shift-ctrl-m = 'exec-and-forget open -a "Mail"'
          cmd-alt-shift-ctrl-c = 'exec-and-forget open -a "Calendar"'
          cmd-alt-shift-ctrl-w = 'exec-and-forget open -a "WhatsApp"'
          cmd-alt-shift-ctrl-s = 'exec-and-forget open -a "System Preferences"'
          cmd-alt-shift-ctrl-p = 'exec-and-forget open -a "Passwords"'
          cmd-alt-shift-ctrl-a = 'exec-and-forget open -a "Activity Monitor"'

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

          alt-shift-1 = ['move-node-to-workspace 1', 'workspace 1']
          alt-shift-2 = ['move-node-to-workspace 2', 'workspace 2']
          alt-shift-3 = ['move-node-to-workspace 3', 'workspace 3']
          alt-shift-4 = ['move-node-to-workspace 4', 'workspace 4']
          alt-shift-5 = ['move-node-to-workspace 5', 'workspace 5']
          alt-shift-6 = ['move-node-to-workspace 6', 'workspace 6']
          alt-shift-7 = ['move-node-to-workspace 7', 'workspace 7']
          alt-shift-8 = ['move-node-to-workspace 8', 'workspace 8']
          alt-shift-9 = ['move-node-to-workspace 9', 'workspace 9']

          # ensure apps that i care are moved to the right workspaces

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
          if.app-id = 'app.zen-browser.zen'
          run = 'move-node-to-workspace 1'
          check-further-callbacks = true

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

          # ensure PIP doesn't get tiled

          [[on-window-detected]]
          if.app-id = 'app.zen-browser.zen'
          if.window-title-regex-substring = 'Picture-in-Picture'
          run = ['layout floating']

          # prevent apps to go to dumpster

          [[on-window-detected]]
          if.app-id = 'com.apple.finder'
          check-further-callbacks = false
          run = ['layout tiling']

          [[on-window-detected]]
          if.app-id = 'com.apple.systempreferences'
          check-further-callbacks = false
          run = ['layout floating']

          # move everything else to the workspace 9 (dumpster)
          # this should run last
          # for anything above, always ensure that check-further-callbacks is false

          [[on-window-detected]]
          check-further-callbacks = true
          run = 'move-node-to-workspace 9'
        '';
        description = "Config to use for {file} `aerospace.toml`.";
      };
    };
  };

  config = (
    lib.mkIf (cfg.enable) {
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.aerospace = {
        command =
          "${cfg.package}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
          + (lib.optionalString (cfg.config != "") " --config-path ${configFile}");
        serviceConfig = {
          KeepAlive = false;
          RunAtLoad = true;
        };
      };
    }
  );
}
