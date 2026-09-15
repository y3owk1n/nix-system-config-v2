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

      # tiling
      [tiling]
      enabled = true
      layout = "${config.xdg.configHome}/mimi/tiling/strip.py"
      layout_mode = "resident"
      relayout_on_drag = true

      # Windows no layout ever sees. These used to be the float list in
      # rules.py; a rule here applies to every layout.
      [[tiling.rules]]
      bundle_id = "com.apple.systempreferences"
      manage = false

      [[tiling.rules]]
      bundle_id = "com.apple.finder"
      manage = false

      [[tiling.rules]]
      bundle_id = "com.apple.Passwords"
      manage = false

      [[tiling.rules]]
      bundle_id = "com.apple.ActivityMonitor"
      manage = false

      [[tiling.rules]]
      bundle_id = "skula.wBlock"
      manage = false

      [[tiling.rules]]
      narrower_than = 400
      shorter_than = 300
      manage = false

      # Safari's settings window is titled after the pane it shows.
      [[tiling.rules]]
      bundle_id = "com.apple.Safari"
      title = "^(General|Tabs|AutoFill|Passwords|Search|Security|Privacy|Websites|Profiles|Extensions|Advanced|Developer|Feature Flags)$"
      manage = false

      [[tiling.rules]]
      bundle_id = "com.apple.Safari"
      space = 1

      [[tiling.rules]]
      bundle_id = "org.nixos.firefox"
      space = 1

      [[tiling.rules]]
      bundle_id = "com.brave.Browser"
      space = 1

      [[tiling.rules]]
      bundle_id = "com.mitchellh.ghostty"
      space = 1

      [[tiling.rules]]
      bundle_id = "com.apple.Terminal"
      space = 1

      [[tiling.rules]]
      bundle_id = "com.apple.Notes"
      space = 1

      [[tiling.rules]]
      bundle_id = "com.hnc.Discord"
      space = 2

      [[tiling.rules]]
      bundle_id = "net.whatsapp.WhatsApp"
      space = 2

      [[tiling.rules]]
      bundle_id = "com.apple.mail"
      space = 2

      [[tiling.rules]]
      bundle_id = "com.canva.affinity"
      space = 3

      [tiling.animation]
      enabled = true
      duration_ms = 100
      easing = "ease-out"

      [tiling.dropzone]
      enabled = true
      color = "#B3${config.lib.stylix.colors.base02}"
      outline_color = "#${config.lib.stylix.colors.base02}"
      outline_width = 2
      radius = 12

      [tiling.stackbar]
      enabled = true
      step = 14
      taper = 10

      [mouse]
      focus_follows_mouse = true

      [border]
      enabled = true
      placement = "inside"
      hide_when_single = true
      active_color = "#${config.lib.stylix.colors.base04}"
      # inactive_color = "#00000000"
    '';
  };
}
