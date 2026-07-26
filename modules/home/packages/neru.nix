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
      "Ctrl+S" = ["action move_mouse --selection", "scroll"]

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

      # ============================================================================
      # Virtual Pointer
      # ============================================================================
      [virtual_pointer.ui]
      font_family = "JetBrainsMonoNLNFP-Bold"
    '';
  };
}
