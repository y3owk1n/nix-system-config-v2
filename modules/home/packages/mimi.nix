{ pkgs, ... }:
{
  # ============================================================================
  # Mimi - macOS event daemon that runs your shell commands when things happen
  # ============================================================================

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
    '';
  };
}
