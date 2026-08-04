{
  pkgs,
  config,
  lib,
  username,
  ...
}:
let
  appPath = "/Users/${username}/Applications/Home Manager Apps/Neru.app";
  entitlements = "${appPath}/Contents/Resources/Neru.entitlements";
in
{
  # ============================================================================
  # Neru - OS wide keyboard navigation
  # ============================================================================
  # System-wide application for mouse and keyboard control
  home.activation.signNeru = lib.hm.dag.entryAfter [ "copyApps" ] ''
    if [ -e "${appPath}" ]; then
      echo "Codesigning Neru.app..."
       /usr/bin/codesign --force --deep --sign - \
         --entitlements "${entitlements}" \
         --options runtime \
         --timestamp=none \
         "${appPath}"
    fi
  '';

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
      "Ctrl+S" = "scroll"

      # ============================================================================
      # Hints
      # ============================================================================
      [hints]
      enabled = false

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
      grid_cols = 3
      grid_rows = 3
      keys = "gcrhtnmwv"
      min_size_width = 1
      min_size_height = 1

      [recursive_grid.animation]
      enabled = true

      [recursive_grid.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"
      line_width = 1
      # highlight_color = "#00000000"
      text_color = "#00000000"

      [recursive_grid.hotkeys]
      # disable defaults
      # "space" = "__disabled__"
      # "shift+l" = "__disabled__"
      "Shift+M" = "__disabled__"
      "Shift+I" = "__disabled__"
      "Shift+U" = "__disabled__"
      "Shift+R" = "__disabled__"
      "`" = "__disabled__"

      "Tab" = "toggle-cursor-follow-selection"

      "," = "action move_mouse --center"
      "." = "action reset"
      "p" = "action left_click --toggle"
      "i" = "action move_mouse"
      "u" = "action left_click"
      "e" = "action middle_click"
      "o" = "action right_click"

      "Ctrl+C" = "idle"
      "Ctrl+J" = "action scroll_down"
      "Ctrl+K" = "action scroll_up"
      "Ctrl+H" = "action scroll_left"
      "Ctrl+L" = "action scroll_right"
      "Ctrl+S" = "macro move_and_scroll"

      "Shift+H" = "action move_cell --direction left"
      "Shift+L" = "action move_cell --direction right"
      "Shift+K" = "action move_cell --direction up"
      "Shift+J" = "action move_cell --direction down"

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

      # ============================================================================
      # Held Repeat
      # ============================================================================
      [held_repeat]
      enabled = true

      # ============================================================================
      # Smooth Cursor
      # ============================================================================
      [smooth_cursor]
      move_mouse_enabled = true
      steps = 30
      max_duration = 100

      # ============================================================================
      # Smooth Scroll
      # ============================================================================
      [smooth_scroll]
      enabled = true
      steps = 300
      max_duration = 300
      duration_per_pixel = 20.00

      # ============================================================================
      # Mouse Action Indicator
      # ============================================================================
      [mouse_action_indicator]
      enabled = true

      # ============================================================================
      # Mode Indicator
      # ============================================================================
      [mode_indicator.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"

      # ============================================================================
      # Virtual Pointer
      # ============================================================================
      [virtual_pointer.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"

      # ============================================================================
      # Macro
      # ============================================================================
      [macros]
      move_and_scroll = "run 'action move_mouse --selection' 'scroll'"
    '';
  };
}
