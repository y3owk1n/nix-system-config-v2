{
  pkgs,
  username,
  ...
}:

{
  # ============================================================================
  # Home Manager
  # ============================================================================

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    inherit username;
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.05";

    shell.enableFishIntegration = true;
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

  # ============================================================================
  # Programs
  # ============================================================================

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  xdg.enable = true;
}
