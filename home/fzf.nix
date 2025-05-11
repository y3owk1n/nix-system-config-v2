{ ... }:
{
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    tmux.enableShellIntegration = true;
    colors = {
      "bg+" = "#363a4f";
      bg = "#24273a";
      spinner = "#f4dbd6";
      hl = "#ed8796";
      fg = "#cad3f5";
      header = "#ed8796";
      info = "#8aadf4";
      pointer = "#f4dbd6";
      marker = "#f4dbd6";
      "fg+" = "#cad3f5";
      prompt = "#8aadf4";
      border = "#8aadf4";
      "hl+" = "#ed8796";
      gutter = "#24273a";
    };
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--style full"
      "--layout reverse"
      "--tmux center"
    ];
    fileWidgetCommand = "fd --exclude .git --type f"; # for when ctrl-t is pressed
    changeDirWidgetCommand = "fd --type d --hidden --follow --max-depth 3 --exclude .git";
  };
}
