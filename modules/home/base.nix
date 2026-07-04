{ pkgs, username, ... }: {
  home = {
    inherit username;
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
    stateVersion = "26.05";
    shell.enableShellIntegration = true;
    shellAliases = {
      gg = "lazygit";
      c = "clear";
      x = "exit";
      cat = "bat";
      tx = "tmux kill-server";
      vim = "nvim";
    };
  };

  programs.home-manager.enable = true;

  xdg.enable = true;
}
