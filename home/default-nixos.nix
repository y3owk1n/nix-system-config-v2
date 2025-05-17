{
  username,
  ...
}:

{
  # import sub modules
  imports = [
    ./apps-nixos.nix
    ./packages/bat.nix
    ./packages/direnv.nix
    ./packages/editorconfig.nix
    ./packages/eza.nix
    ./packages/fish.nix
    ./packages/fzf.nix
    ./packages/git.nix
    ./packages/go.nix
    ./packages/lazygit.nix
    ./packages/nvim.nix
    ./packages/sesh.nix
    ./packages/starship.nix
    ./packages/tmux.nix
    ./custom/cpenv.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = username;
    homeDirectory = "/home/${username}";

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

  catppuccin = {
    enable = true;
    flavor = "macchiato";
    accent = "blue";
  };
}
