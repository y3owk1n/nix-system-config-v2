{ pkgs, ... }:
{
  # ============================================================================
  # Ghostty Terminal Configuration
  # ============================================================================

  programs.ghostty = {
    enable = true;
    # Use the binary release instead of building from source for better performance
    package = pkgs.ghostty-bin;
    clearDefaultKeybinds = true;
    installBatSyntax = true;
    installVimSyntax = true;
    settings = {
      # Use JetBrains Mono with Nerd Font glyphs
      font-family = "JetBrainsMonoNL Nerd Font";

      # Disable ligatures and contextual alternates for better code readability
      font-feature = [
        "-calt"
        "-liga"
        "-dlig"
      ];

      # Window padding for better readability
      window-padding-x = 10;
      window-padding-y = 10;
      window-padding-balance = true;

      # macOS-specific settings
      window-save-state = "never"; # Don't save/restore window state
      macos-titlebar-style = "hidden"; # Hide titlebar for cleaner look

      # Behavior settings
      confirm-close-surface = false; # Don't confirm closing tabs
      quit-after-last-window-closed = true; # Quit when last window closes
      macos-option-as-alt = true; # Treat Option key as Alt
      mouse-hide-while-typing = true; # Hide mouse cursor while typing
      copy-on-select = false; # Don't auto-copy on selection

      # ============================================================================
      # Custom Keybindings
      # ============================================================================
      # macOS-style keybindings with some custom additions
      keybind = [
        "super+shift+comma=reload_config"
        "super+shift+w=close_window"
        "super+w=close_surface"
        "super+q=quit"
        "super+comma=open_config"
        "super+c=copy_to_clipboard"
        "super+v=paste_from_clipboard"
        "super+shift+equal=increase_font_size:1"
        "super+minus=decrease_font_size:1"
        "super+0=reset_font_size"
      ];
    };
  };
}
