{
  username,
  hostname,
  pkgs,
  ...
}:
{
  # enable flakes globally
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.fish.enable = true;
  # environment.shells = [ pkgs.fish ];

  environment.systemPackages = with pkgs; [
    coreutils
    neovim
    gcc
    unzip
  ];
}
