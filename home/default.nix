{
  username,
  ...
}:

{
  # import sub modules
  imports = [
    ./apps.nix
    ./bat.nix
    ./btop.nix
    ./editorconfig.nix
    ./eza.nix
    ./fish.nix
    ./fzf.nix
    ./gh.nix
    ./ghostty.nix
    ./git.nix
    ./go.nix
    ./kanata.nix
    ./lazygit.nix
    ./nvim.nix
    ./sesh.nix
    ./starship.nix
    ./tmux.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    activation = {
      # NOTE: Do not delete this! Uncomment this when you want to use spotlight search
      # This will enable spotlight search to index installed apps
      # rsync-home-manager-applications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      #   rsyncArgs="--archive --checksum --chmod=-w --copy-unsafe-links --delete"
      #   apps_source="$genProfilePath/home-path/Applications"
      #   moniker="Home Manager Trampolines"
      #   app_target_base="${config.home.homeDirectory}/Applications"
      #   app_target="$app_target_base/$moniker"
      #   mkdir -p "$app_target"
      #   ${pkgs.rsync}/bin/rsync $rsyncArgs "$apps_source/" "$app_target"
      # '';
    };

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
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
