{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.govim;

  configFile = pkgs.writeScript "govim.toml" cfg.config;
in

{
  options = {
    govim = with lib.types; {
      enable = lib.mkEnableOption "Govim keyboard navigation";

      package = lib.mkPackageOption pkgs "govim" { };

      config = lib.mkOption {
        type = types.lines;
        default = ''
          [general]
          excluded_apps = [
              "com.mitchellh.ghostty",
          ]
          include_menubar_hints = false
          include_dock_hints = false

          [accessibility]
          accessibility_check_on_start = true
          clickable_roles = [
              "AXButton",
              "AXCheckBox",
              "AXRadioButton",
              "AXPopUpButton",
              "AXMenuItem",
              "AXMenuBarItem",
              "AXDockItem",
              "AXApplicationDockItem",
              "AXLink",
              "AXTextField",
              "AXTextArea",
          ]
          scrollable_roles = [
              "AXScrollArea",
          ]

          [[accessibility.app_configs]]
          bundle_id = "com.apple.mail"
          additional_clickable_roles = ["AXStaticText"]

          [[accessibility.app_configs]]
          bundle_id = "com.apple.Notes"
          additional_clickable_roles = ["AXStaticText"]

          [accessibility.electron_support]
          enable = true
          additional_bundles = []

          [hotkeys]
          activate_hint_mode = "Ctrl+F"
          activate_hint_mode_with_actions = "Ctrl+G"
          activate_scroll_mode = "Ctrl+S"

          [hints]
          hint_characters = "aoeuidhtns"
          font_size = 12
          font_family = "JetBrainsMonoNLNFP-ExtraBold"
          background_color = "#FFD700"
          text_color = "#000000"
          matched_text_color = "#0066CC"
          border_radius = 4
          padding = 2
          border_width = 1
          border_color = "#000000"
          opacity = 0.95

          action_background_color = "#66CCFF"
          action_text_color = "#000000"
          action_matched_text_color = "#003366"
          action_border_color = "#000000"
          action_opacity = 0.95

          menubar = false
          dock = false

          [scroll]
          scroll_speed = 50
          highlight_scroll_area = true
          highlight_color = "#FF0000"
          highlight_width = 2
          page_height = 1200
          half_page_multiplier = 0.5
          full_page_multiplier = 0.9
          scroll_to_edge_iterations = 20
          scroll_to_edge_delta = 5000

          [performance]
          max_hints_displayed = 500
          debounce_ms = 50
          cache_duration_ms = 100
          max_concurrent_queries = 10

          [logging]
          log_level = "info"
          log_file = ""
          structured_logging = true
        '';
        description = "Config to use for {file} `govim.toml`.";
      };
    };
  };

  config = (
    lib.mkIf (cfg.enable) {
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.govim = {
        command =
          "${cfg.package}/bin/govim launch"
          + (lib.optionalString (cfg.config != "") " --config ${configFile}");
        serviceConfig = {
          KeepAlive = false;
          RunAtLoad = true;
        };
      };
    }
  );
}
