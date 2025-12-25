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

    ../packages/gpg.nix
    ../packages/pass.nix
  ];
}
