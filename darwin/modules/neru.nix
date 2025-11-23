{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.neru;

  configFile = pkgs.writeScript "neru.toml" cfg.config;
in

{
  options = {
    neru = with lib.types; {
      enable = lib.mkEnableOption "Neru keyboard navigation";

      package = lib.mkPackageOption pkgs "neru" { };

      config = lib.mkOption {
        type = types.lines;
        default = ''
          [general]
          restore_cursor_position = true

          [hotkeys]
          "Ctrl+F" = "grid -a left_click"
          "Ctrl+G" = "grid"
          "Ctrl+S" = "action scroll"

          [hints]
          enabled = false

          [grid]
          font_family = "JetBrainsMonoNLNFP-ExtraBold"

          sublayer_keys = "gcrhtnmwv"

          [action]
          left_click_key = "h"
          middle_click_key = "t"
          right_click_key = "n"
          mouse_down_key = "c"
          mouse_up_key = "r"

          [smooth_cursor]
          move_mouse_enabled = true
          steps = 10
          delay = 1

          [logging]
          log_level = "info"
          disable_file_logging = true
        '';
        description = "Config to use for {file} `neru.toml`.";
      };
    };
  };

  config = (
    lib.mkIf (cfg.enable) {
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.neru = {
        command =
          "${cfg.package}/Applications/Neru.app/Contents/MacOS/Neru launch"
          + (lib.optionalString (cfg.config != "") " --config ${configFile}");
        serviceConfig = {
          KeepAlive = false;
          RunAtLoad = true;
        };
      };
    }
  );
}
