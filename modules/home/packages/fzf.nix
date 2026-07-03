_: {
  programs.fzf = {
    enable = true;
    tmux = {
      enableShellIntegration = true;
      shellIntegrationOptions = [
        "-p 50%"
      ];
    };
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--style full"
      "--layout reverse"
      "--tmux center"
    ];
    historyWidget.command = ""; # Disable history widget and use atuin for Ctrl-R
  };
}
