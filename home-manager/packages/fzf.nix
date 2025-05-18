{ ... }:
{
  programs.fzf = {
    enable = true;
    tmux.enableShellIntegration = true;
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
