{ pkgs, config, ... }:
{
  # ============================================================================
  # Neru - OS wide keyboard navigation
  # ============================================================================
  # System-wide application for mouse and keyboard control

  services.neru = {
    enable = true;
    # package = pkgs.neru;
    package = pkgs.neru-source;
    config = ''
      # ============================================================================
      # Theme
      # ============================================================================
      [theme.light]
      surface = "#${config.lib.stylix.colors.base00}"
      accent = "#${config.lib.stylix.colors.base04}"
      accent_alt = "#${config.lib.stylix.colors.base04}"
      on_accent_alt = "#${config.lib.stylix.colors.base07}"
      text = "#${config.lib.stylix.colors.base05}"

      [theme.dark]
      surface = "#${config.lib.stylix.colors.base00}"
      accent = "#${config.lib.stylix.colors.base04}"
      accent_alt = "#${config.lib.stylix.colors.base04}"
      on_accent_alt = "#${config.lib.stylix.colors.base07}"
      text = "#${config.lib.stylix.colors.base05}"

      # ============================================================================
      # General Settings
      # ============================================================================
      [general]
      hide_overlay_in_screen_share = true
      passthrough_unbounded_keys = true
      exec_shell = "/bin/dash"
      exec_shell_args = ["-lc"]

      # ============================================================================
      # Hotkeys
      # ============================================================================
      [hotkeys]
      "Ctrl+F" = "recursive_grid --cursor-selection-mode hold"
      "Ctrl+S" = ["action move_mouse --selection", "scroll"]

      # ============================================================================
      # Hints
      # ============================================================================
      [hints]
      enabled = false
      visible_check_enabled = false

      hint_characters = "aeudhtnspyfgcrqjkxbmwvz"
      include_menubar_hints = true
      include_dock_hints = true
      include_nc_hints = true
      include_stage_manager_hints = true
      include_pip_hints = true
      include_screen_capture_hints = true
      detect_mission_control = true
      on_mission_control_activated = "hints --action left_click"
      on_mission_control_deactivated = "idle"

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
        "AXMenuItem",
        "AXCell",
        "AXRow",
      	"AXMenuButton",
      	"AXGenericElement",
      ]

      additional_menubar_hints_targets = [
        "com.apple.TextInputMenuAgent",
        "com.apple.controlcenter",
        "com.apple.systemuiserver",
        "com.y3owk1n.neru",
      	"com.openai.codex",
      	"com.google.antigravity",
      ]

      [[hints.app_configs]]
      bundle_id = "com.apple.Safari"
      visible_check_enabled = true

      [hints.additional_ax_support]
      enable = true

      additional_electron_bundles = ["com.openai.codex", "com.hnc.discord", "com.google.antigravity"]
      additional_chromium_bundles = []
      additional_firefox_bundles = []
      additional_webkit_bundles = []

      [hints.boundary_highlight]
      enabled = true

      # ============================================================================
      # Grid Navigation
      # ============================================================================
      [grid]
      enabled = false

      # ============================================================================
      # Recursive Grid Navigation
      # ============================================================================
      [recursive_grid]
      enabled = true
      grid_cols = 5
      grid_rows = 5
      keys = "fgcrlaoeuidhtns;qjkxbmwvz"
      min_size_width = 1
      min_size_height = 1

      [recursive_grid.animation]
      enabled = false

      [recursive_grid.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"
      line_width = 1
      # highlight_color = "#B00A1338"
      highlight_color = "#00000000"
      text_color = "#00000000"

      [recursive_grid.hotkeys]
      # disable defaults
      # "Space" = "__disabled__"
      "Shift+L" = "__disabled__"
      "Shift+M" = "__disabled__"
      "Shift+I" = "__disabled__"
      "Shift+U" = "__disabled__"
      "Shift+R" = "__disabled__"
      "`" = "__disabled__"

      "Tab" = "toggle-cursor-follow-selection"

      "'" = "action move_mouse"
      "," = "action move_mouse --center"
      "." = "action reset"
      "p" = "action mouse_down"
      "y" = "action mouse_up"
      "Enter" = "action left_click"
      "Shift+Enter" = "action middle_click"
      "Ctrl+Enter" = "action right_click"
      "Space" = "action left_click"
      "Shift+Space" = "action middle_click"
      "Ctrl+Space" = "action right_click"

      "Ctrl+C" = "idle"
      "Ctrl+J" = "action scroll_down"
      "Ctrl+K" = "action scroll_up"
      "Ctrl+H" = "action scroll_left"
      "Ctrl+L" = "action scroll_right"

      # [[recursive_grid.app_configs]]
      # bundle_id = "com.brave.Browser"
      # hotkeys = {
      #   "1" = ["action right_click", "action sleep 0.1", "action feed o p e n enter m d a enter"],
      #   "2" = ["action right_click", "action sleep 0.1", "action feed o p e n enter s k b enter"],
      #   "3" = ["action right_click", "action sleep 0.1", "action feed o p e n enter t r a enter"],
      #   "4" = ["action right_click", "action sleep 0.1", "action feed o p e n enter m a d enter"],
      #   "5" = ["action right_click", "action sleep 0.1", "action feed o p e n enter w a k enter"],
      # }

      # ============================================================================
      # Scroll
      # ============================================================================

      [scroll]
      scroll_step = 100

      [scroll.hotkeys]
      # disable defaults
      "Shift+L" = "__disabled__"
      "Shift+M" = "__disabled__"
      "Shift+I" = "__disabled__"
      "Shift+U" = "__disabled__"
      "Shift+R" = "__disabled__"

      "Ctrl+C" = "idle"
      "f" = "action feed ctrl+f"

      "Enter" = "action left_click"
      "Shift+Enter" = "action middle_click"
      "Ctrl+Enter" = "action right_click"
      "Space" = "action left_click"
      "Shift+Space" = "action middle_click"
      "Ctrl+Space" = "action right_click"

      [mouse_action_indicator]
      enabled = true

      # ============================================================================
      # Mode Indicator
      # ============================================================================
      [mode_indicator.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"
    '';
  };
}
