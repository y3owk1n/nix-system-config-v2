{
  ...
}:
{
  # import shared modules
  imports = [
    ../modules/ai.nix
    ../modules/git.nix
    ../modules/shell.nix
    ../modules/utils.nix
    ../modules/nvim.nix
    ../modules/terminal.nix
    ../modules/security.nix

    ../packages/hyprland.nix
  ];
}
