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
          [hotkeys]
          "Ctrl+F" = "grid left_click"
          "Ctrl+R" = "grid right_click"
          "Ctrl+G" = "grid context_menu"
          "Ctrl+S" = "grid scroll"

          [hints]
          enabled = false

          [grid]
          font_family = "JetBrainsMonoNLNFP-ExtraBold"

          characters = "ahotenusigcrplyfmqwjvkzx"
          sublayer_keys = "gcrhtnmwv"

          [grid.left_click]
          restore_cursor = true

          [grid.right_click]
          restore_cursor = true

          [grid.double_click]
          restore_cursor = true

          [grid.triple_click]
          restore_cursor = true

          [grid.middle_click]
          restore_cursor = true
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
