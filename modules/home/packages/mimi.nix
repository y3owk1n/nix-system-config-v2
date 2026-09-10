{
  pkgs,
  config,
  lib,
  ...
}:
let
  appPath = "${config.home.homeDirectory}/Applications/Home Manager Apps/Mimi.app";
  entitlements = "${appPath}/Contents/Resources/Mimi.entitlements";
in
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  # ============================================================================
  # Mimi - macOS event daemon that runs your shell commands when things happen
  # ============================================================================

  home.activation.signMimi = lib.hm.dag.entryAfter [ "copyApps" ] ''
    if [ -e "${appPath}" ]; then
      echo "Codesigning Mimi.app..."
       /usr/bin/codesign --force --deep --sign - \
         --entitlements "${entitlements}" \
         --options runtime \
         --timestamp=none \
         "${appPath}"
    fi
  '';

  home.packages = [ pkgs.python3 ];

  xdg.configFile."mimi/tiling" = {
    source = ../../../config/mimi/tiling;
    recursive = true;
  };

  services.mimi = {
    enable = true;
    # package = pkgs.mimi;
    package = pkgs.mimi-source;
    config = ''
      [settings]
      hook_shell = "/bin/dash"

      [systray]
      # Show the Mimi menu bar item while the daemon is running.
      enabled = true
      show_workspace_number = true

      [hooks]
      # App process started.
      on_app_launch = [
      	{ run = "command -v neru >/dev/null 2>&1 && neru action move_mouse --window", async = true },
      ]

      # App comes to foreground.
      on_app_activate = [
      	{ run = "command -v neru >/dev/null 2>&1 && neru action move_mouse --window", async = true },
      ]

      # Focused window changed.
      on_window_focus = [
      	{ run = "command -v neru >/dev/null 2>&1 && neru action move_mouse --window", async = true },
      ]

      # Window finished resizing (debounced, fires once after resize ends).
      on_window_resize = [
      	{ run = "command -v neru >/dev/null 2>&1 && neru action move_mouse --window", async = true },
      ]

      # tiling
      [tiling]
      enabled = true
      layout = "${config.xdg.configHome}/mimi/tiling/strip.py"
      layout_mode = "resident"
      relayout_on_drag = true

      [tiling.animation]
      enabled = true
      duration_ms = 100
      easing = "ease-out"

      [border]
      enabled = true
      active_color = "#${config.lib.stylix.colors.base04}"
      inactive_color = "#00000000"
    '';
  };
}
