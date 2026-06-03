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

      # App comes to foreground.
      on_app_activate = [
      	"command -v neru >/dev/null 2>&1 && neru action move_mouse --window",
      ]

      # Focused window changed.
      on_window_focus = [
      	"command -v neru >/dev/null 2>&1 && neru action move_mouse --window",
      ]
    '';
  };
}
