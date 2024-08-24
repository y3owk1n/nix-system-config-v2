{ ... }:
{
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    colors = {
      "bg+" = "#363a4f";
      bg = "#24273a";
      spinner = "#f4dbd6";
      hl = "#ed8796";
      fg = "#cad3f5";
      header = "#ed8796";
      info = "#c6a0f6";
      pointer = "#f4dbd6";
      marker = "#f4dbd6";
      "fg+" = "#cad3f5";
      prompt = "#c6a0f6";
      "hl+" = "#ed8796";
    };
    defaultCommand = "fd --type f --hidden --exclude .git";
    fileWidgetCommand = "fd --exclude .git --type f"; # for when ctrl-t is pressed
    changeDirWidgetCommand = "fd --type d --hidden --follow --max-depth 3 --exclude .git";
  };
}
