{
  ...
}:

{
  # import shared modules
  imports = [
    ../modules/development.nix
    ../modules/system.nix
    ../modules/security.nix
    ../modules/shell.nix
    ../modules/macos.nix

    # Editor
    ../packages/nvim.nix

    # ============================================================================
    # Custom Modules
    # ============================================================================
    ../custom/asr.nix
    ../custom/cpenv.nix
    ../custom/cmd.nix
    ../custom/passx.nix
  ];
}
