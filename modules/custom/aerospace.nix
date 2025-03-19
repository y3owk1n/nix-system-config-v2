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
          default-root-container-layout = 'tiles'
          default-root-container-orientation = 'auto'

          enable-normalization-flatten-containers = true
          enable-normalization-opposite-orientation-for-nested-containers = true

          on-focused-monitor-changed = ['move-mouse monitor-lazy-center']

          on-focus-changed = ["move-mouse window-force-center"]

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

          cmd-alt-shift-ctrl-h = 'focus left'
          cmd-alt-shift-ctrl-j = 'focus down'
          cmd-alt-shift-ctrl-k = 'focus up'
          cmd-alt-shift-ctrl-l = 'focus right'

          ctrl-shift-h = 'move left'
          ctrl-shift-j = 'move down'
          ctrl-shift-k = 'move up'
          ctrl-shift-l = 'move right'

          # cmd-alt-shift-ctrl-minus = 'resize smart -50'
          # cmd-alt-shift-ctrl-equal = 'resize smart +50'

          cmd-alt-shift-ctrl-m = 'fullscreen'

          # alt-backslash = 'layout tiles horizontal vertical'
          # alt-minus = 'layout accordion horizontal vertical'

          cmd-alt-shift-ctrl-backslash = 'join-with down'
          cmd-alt-shift-ctrl-minus = 'join-with right'

          cmd-alt-shift-ctrl-1 = 'workspace 1'
          cmd-alt-shift-ctrl-2 = 'workspace 2'
          cmd-alt-shift-ctrl-3 = 'workspace 3'
          cmd-alt-shift-ctrl-4 = 'workspace 4'
          cmd-alt-shift-ctrl-5 = 'workspace 5'
          cmd-alt-shift-ctrl-6 = 'workspace 6'
          cmd-alt-shift-ctrl-7 = 'workspace 7'
          cmd-alt-shift-ctrl-8 = 'workspace 8'
          cmd-alt-shift-ctrl-9 = 'workspace 9'
          cmd-alt-shift-ctrl-0 = 'balance-sizes'

          ctrl-shift-1 = ['move-node-to-workspace 1', 'workspace 1']
          ctrl-shift-2 = ['move-node-to-workspace 2', 'workspace 2']
          ctrl-shift-3 = ['move-node-to-workspace 3', 'workspace 3']
          ctrl-shift-4 = ['move-node-to-workspace 4', 'workspace 4']
          ctrl-shift-5 = ['move-node-to-workspace 5', 'workspace 5']
          ctrl-shift-6 = ['move-node-to-workspace 6', 'workspace 6']
          ctrl-shift-7 = ['move-node-to-workspace 7', 'workspace 7']
          ctrl-shift-8 = ['move-node-to-workspace 8', 'workspace 8']
          ctrl-shift-9 = ['move-node-to-workspace 9', 'workspace 9']

          cmd-alt-shift-ctrl-r = 'flatten-workspace-tree'

          # cmd-alt-shift-ctrl-c = 'reload-config'

          cmd-alt-shift-ctrl-t = 'layout floating tiling' # 'floating toggle' in i3

          [[on-window-detected]]
          if.app-id = 'com.apple.Safari'
          run = 'move-node-to-workspace 1'

          [[on-window-detected]]
          if.app-id = 'com.brave.Browser'
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
          if.app-id = 'com.apple.reminders'
          run = 'move-node-to-workspace 3'

          [[on-window-detected]]
          if.app-id = 'net.whatsapp.WhatsApp'
          run = 'move-node-to-workspace 4'

          [[on-window-detected]]
          if.app-id = 'com.apple.MobileSMS'
          run = 'move-node-to-workspace 4'

          [[on-window-detected]]
          if.app-id = 'com.apple.mail'
          run = 'move-node-to-workspace 5'

          [[on-window-detected]]
          if.app-id = 'com.apple.iCal'
          run = 'move-node-to-workspace 5'

          [[on-window-detected]]
          if.app-id = 'com.adobe.Photoshop'
          run = 'move-node-to-workspace 6'

          [[on-window-detected]]
          if.app-id = 'com.adobe.illustrator'
          run = 'move-node-to-workspace 6'

          [[on-window-detected]]
          if.app-id = 'com.apple.ScreenSharing'
          run = 'move-node-to-workspace 7'

          [[on-window-detected]]
          if.app-id = 'com.carriez.rustdesk'
          run = 'move-node-to-workspace 7'

          [[on-window-detected]]
          if.app-id = 'com.apple.Music'
          run = 'move-node-to-workspace 8'

          [[on-window-detected]]
          if.app-id = 'com.apple.finder'
          run = 'layout floating'

          [[on-window-detected]]
          if.app-id = 'com.apple.systempreferences'
          run = 'layout floating'

          [[on-window-detected]]
          if.app-id = 'com.apple.archiveutility'
          run = 'layout floating'

          [[on-window-detected]]
          if.app-id = 'com.logi.optionplus'
          run = 'layout floating'

          [[on-window-detected]]
          if.app-id = 'app.zen-browser.zen'
          if.window-title-regex-substring = 'Picture-in-Picture'
          run = ['layout floating']
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
