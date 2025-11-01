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
          hint_characters = "aoeuidhtns"
          hint_style = "alphabet"

          [accessibility]
          # Accessibility roles that are treated as clickable
          # Users can add or remove roles as needed
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

          # Accessibility roles that are treated as scrollable
          # Users can add or remove roles as needed
          scrollable_roles = [
              "AXScrollArea",
          ]

          # Example: Add custom roles for Safari
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
          # Activate hint mode with action selection (choose click type after typing hint)
          activate_hint_mode_with_actions = "Ctrl+G"

          # Activate scroll mode for vim-style scrolling
          activate_scroll_mode = "Ctrl+S"

          # Note: Escape key is hardcoded to exit any active mode

          [hints]
          # Font size for hint labels
          font_size = 12

          # Font family (leave empty for system default)
          font_family = "JetBrainsMonoNLNFP-ExtraBold"

          # Background color (hex format)
          background_color = "#FFD700"

          # Text color (hex format)
          text_color = "#000000"

          # Matched text color - color for characters that have been typed (hex format)
          matched_text_color = "#0066CC"

          # Border radius (pixels)
          border_radius = 4

          # Padding (pixels)
          padding = 2

          # Border width (pixels)
          border_width = 1

          # Border color (hex format)
          border_color = "#000000"

          # Opacity (0.0 to 1.0)
          opacity = 0.95

          # Action keys for hint mode with actions (hardcoded):
          #   l = left click, r = right click, d = double click, m = middle click

          # Include additional targets in hint mode
          # Show hints on the macOS menu bar
          menubar = false
          # Show hints on the Dock
          dock = false

          [scroll]
          # Base scroll amount for j/k keys in pixels
          scroll_speed = 50

          # Highlight the active scroll area with a border
          highlight_scroll_area = true

          # Highlight border color (hex format)
          highlight_color = "#FF0000"

          # Highlight border width in pixels
          highlight_width = 2

          # Estimated page height in pixels (used for calculating Ctrl+D/U scroll distance)
          page_height = 1200

          # Half-page scroll multiplier for Ctrl+D/U (0.5 = 600px with default page_height)
          half_page_multiplier = 0.5

          # Full-page scroll multiplier (not currently used)
          full_page_multiplier = 0.9

          # Number of scroll events to send for gg/G commands
          scroll_to_edge_iterations = 20

          # Pixels to scroll per iteration for gg/G (total = iterations * delta)
          scroll_to_edge_delta = 5000

          [performance]
          # Maximum number of hints to display
          max_hints_displayed = 500

          # Debounce time for UI updates (milliseconds)
          debounce_ms = 50

          # Cache duration for UI element tree (milliseconds)
          cache_duration_ms = 100

          # Maximum concurrent element queries
          max_concurrent_queries = 10

          [logging]
          # Log level: "debug", "info", "warn", "error"
          log_level = "info"

          # Log file location (empty for default: ~/Library/Logs/govim/app.log)
          log_file = ""

          # Enable structured logging
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
