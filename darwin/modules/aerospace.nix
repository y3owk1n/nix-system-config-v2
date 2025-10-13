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
          cmd-alt-shift-ctrl-l = 'workspace-back-and-forth'

          cmd-alt-shift-ctrl-b = 'workspace b' # Browser
          cmd-alt-shift-ctrl-t = 'workspace t' # Terminal
          cmd-alt-shift-ctrl-n = 'workspace n' # Notes
          cmd-alt-shift-ctrl-e = 'workspace e' # Email
          cmd-alt-shift-ctrl-c = 'workspace c' # Calendar
          cmd-alt-shift-ctrl-m = 'workspace m' # Messaging
          cmd-alt-shift-ctrl-d = 'workspace d' # Design
          cmd-alt-shift-ctrl-s = 'workspace s' # Screen sharing
          cmd-alt-shift-ctrl-x = 'workspace x' # Whatever else goes here
          cmd-alt-shift-ctrl-0 = 'flatten-workspace-tree'

          alt-shift-b = ['move-node-to-workspace b', 'workspace b']
          alt-shift-t = ['move-node-to-workspace t', 'workspace t']
          alt-shift-n = ['move-node-to-workspace n', 'workspace n']
          alt-shift-e = ['move-node-to-workspace e', 'workspace e']
          alt-shift-c = ['move-node-to-workspace c', 'workspace c']
          alt-shift-m = ['move-node-to-workspace m', 'workspace m']
          alt-shift-d = ['move-node-to-workspace d', 'workspace d']
          alt-shift-s = ['move-node-to-workspace s', 'workspace s']
          alt-shift-x = ['move-node-to-workspace x', 'workspace x']

          # ensure apps that i care are moved to the right workspaces

          [[on-window-detected]]
          if.app-id = 'com.apple.Safari'
          run = 'move-node-to-workspace b'

          [[on-window-detected]]
          if.app-id = 'com.apple.SafariTechnologyPreview'
          run = 'move-node-to-workspace b'

          [[on-window-detected]]
          if.app-id = 'com.brave.Browser'
          run = 'move-node-to-workspace b'

          [[on-window-detected]]
          if.app-id = 'app.zen-browser.zen'
          run = 'move-node-to-workspace b'
          check-further-callbacks = true

          [[on-window-detected]]
          if.app-id = 'com.mitchellh.ghostty'
          run = 'move-node-to-workspace t'

          [[on-window-detected]]
          if.app-id = 'com.apple.Terminal'
          run = 'move-node-to-workspace t'

          [[on-window-detected]]
          if.app-id = 'com.apple.Notes'
          run = 'move-node-to-workspace n'

          [[on-window-detected]]
          if.app-id = 'net.whatsapp.WhatsApp'
          run = 'move-node-to-workspace m'

          [[on-window-detected]]
          if.app-id = 'com.apple.MobileSMS'
          run = 'move-node-to-workspace m'

          [[on-window-detected]]
          if.app-id = 'com.apple.mail'
          run = 'move-node-to-workspace e'

          [[on-window-detected]]
          if.app-id = 'com.apple.iCal'
          run = 'move-node-to-workspace c'

          [[on-window-detected]]
          if.app-id = 'com.adobe.Photoshop'
          run = 'move-node-to-workspace d'

          [[on-window-detected]]
          if.app-id = 'com.adobe.illustrator'
          run = 'move-node-to-workspace d'

          [[on-window-detected]]
          if.app-id = 'org.blenderfoundation.blender'
          run = 'move-node-to-workspace d'

          [[on-window-detected]]
          if.app-id = 'com.apple.ScreenSharing'
          run = 'move-node-to-workspace s'

          [[on-window-detected]]
          if.app-id = 'com.carriez.rustdesk'
          run = 'move-node-to-workspace s'

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

          # move everything else to the x workspace (dumpster)
          # this should run last
          # for anything above, always ensure that check-further-callbacks is false

          [[on-window-detected]]
          check-further-callbacks = true
          run = 'move-node-to-workspace x'
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
          KeepAlive = true;
          RunAtLoad = true;
        };
      };
    }
  );
}
