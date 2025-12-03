{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    clearDefaultKeybinds = true;
    installBatSyntax = true;
    installVimSyntax = true;
    settings = {
      font-family = "JetBrainsMonoNL Nerd Font";
      font-feature = [
        "-calt"
        "-liga"
        "-dlig"
      ];
      window-padding-x = 10;
      window-padding-y = 10;
      window-padding-balance = true;
      window-save-state = "never";
      macos-titlebar-style = "hidden";
      confirm-close-surface = false;
      quit-after-last-window-closed = true;
      macos-option-as-alt = true;
      mouse-hide-while-typing = true;
      copy-on-select = false;
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
