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
          excluded_apps = [
              "com.mitchellh.ghostty",
          ]
          include_nc_hints = true

          [accessibility]
          clickable_roles = [
              "AXButton",
              "AXComboBox",
              "AXCheckBox",
              "AXRadioButton",
              "AXLink",
              "AXPopUpButton",
              "AXTextField",
              "AXSlider",
              "AXTabButton",
              "AXSwitch",
              "AXDisclosureTriangle",
              "AXTextArea",
              "AXMenuButton",
              "AXMenuItem",
              "AXCell",
              "AXRow",
          ]

          [accessibility.additional_ax_support]
          enable = true

          [hotkeys]
          "Ctrl+F" = "hints left_click"
          "Ctrl+R" = "hints right_click"
          "Ctrl+G" = "hints context_menu"
          "Ctrl+S" = "hints scroll"

          [hints]
          hint_characters = "aoeuidhtns"
          font_size = 11
          font_family = "JetBrainsMonoNLNFP-ExtraBold"
          padding = 2

          [hints.left_click_hints]
          restore_cursor = true

          [hints.right_click_hints]
          restore_cursor = true

          [hints.double_click_hints]
          restore_cursor = true

          [hints.triple_click_hints]
          restore_cursor = true

          [hints.middle_click_hints]
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
