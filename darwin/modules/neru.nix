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
          include_menubar_hints = false
          include_dock_hints = false
          include_nc_hints = true
          restore_pos_after_left_click = true
          restore_pos_after_right_click = true
          restore_pos_after_middle_click = true
          restore_pos_after_double_click = true

          [accessibility]
          accessibility_check_on_start = true
          clickable_roles = [
              "AXButton",
              "AXComboBox",
              "AXCheckBox",
              "AXRadioButton",
              "AXLink",
              "AXPopUpButton",
              "AXTextField",
              "AXSlider",
              "AXTabGroup",
              "AXTabButton",
              "AXSwitch",
              "AXToolbar",
              "AXDisclosureTriangle",
              "AXTextArea",
              "AXMenuButton",
              "AXMenuItem",
              "AXGroup",
              "AXImage",
              "AXCell",
          ]
          scrollable_roles = [
              "AXScrollArea",
          ]

          [accessibility.electron_support]
          enable = true
          additional_bundles = []

          [hotkeys]
          activate_hint_mode = "Ctrl+F"
          activate_hint_mode_with_actions = "Ctrl+G"
          activate_scroll_mode = "Ctrl+S"

          [hints]
          hint_characters = "aoeuidhtns"
          font_size = 11
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
        description = "Config to use for {file} `neru.toml`.";
      };
    };
  };

  config = (
    lib.mkIf (cfg.enable) {
      environment.systemPackages = [ cfg.package ];

      launchd.user.agents.neru = {
        command =
          "${cfg.package}/Applications/Neru.app/Contents/MacOS/neru launch"
          + (lib.optionalString (cfg.config != "") " --config ${configFile}");
        serviceConfig = {
          KeepAlive = false;
          RunAtLoad = true;
        };
      };
    }
  );
}
