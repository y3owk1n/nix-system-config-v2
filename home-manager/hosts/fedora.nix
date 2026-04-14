{
  nixgl,
  pkgs,
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
    ../packages/neru.nix
  ];

  home.packages = [
    nixgl.packages.${pkgs.system}.nixGLIntel
  ];
}
