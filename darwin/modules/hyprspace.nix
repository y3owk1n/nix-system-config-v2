{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hyprspace;

  configFile = pkgs.writeScript "hyprspace.toml" cfg.config;
in

{
  options = {
    hyprspace = with lib.types; {
      enable = lib.mkEnableOption "Hyprspace window manager";

      package = lib.mkPackageOption pkgs "hyprspace" { };

      config = lib.mkOption {
        type = types.lines;
        default = ''
          start-at-login = false
          after-login-command = []

          default-root-container-layout = 'scroll'
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
          cmd-m = [] # Disable "minimize"

          alt-h = 'focus left'
          alt-j = 'focus down'
          alt-k = 'focus up'
          alt-l = 'focus right'

          alt-shift-h = 'move left'
          alt-shift-j = 'move down'
          alt-shift-k = 'move up'
          alt-shift-l = 'move right'

          alt-shift-minus = 'resize smart -50'
          alt-shift-equal = 'resize smart +50'

          alt-f = 'layout floating tiling'

          alt-m = 'fullscreen'

          cmd-alt-shift-ctrl-f = 'exec-and-forget open -a finder'
          cmd-alt-shift-ctrl-b = 'exec-and-forget open -a firefox'
          cmd-alt-shift-ctrl-t = 'exec-and-forget open -a "Ghostty"'
          cmd-alt-shift-ctrl-n = 'exec-and-forget open -a "Notes"'
          cmd-alt-shift-ctrl-m = 'exec-and-forget open -a "Mail"'
          cmd-alt-shift-ctrl-c = 'exec-and-forget open -a "Calendar"'
          cmd-alt-shift-ctrl-w = 'exec-and-forget open -a "WhatsApp"'
          cmd-alt-shift-ctrl-s = 'exec-and-forget open -a "System Preferences"'
          cmd-alt-shift-ctrl-p = 'exec-and-forget open -a "Passwords"'
          cmd-alt-shift-ctrl-a = 'exec-and-forget open -a "Activity Monitor"'

          cmd-alt-shift-ctrl-1 = 'workspace 1' # Browser
          cmd-alt-shift-ctrl-0 = 'flatten-workspace-tree'
        '';
        description = "Config to use for {file} `aerospace.toml`.";
      };
    };
  };

  config = (
    lib.mkIf (cfg.enable) {
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.hyprspace = {
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
