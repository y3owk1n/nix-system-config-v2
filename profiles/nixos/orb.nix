{ ... }: {
  # ============================================================================
  # NixOS Orbstack VM Profile
  # ============================================================================

  # Inherit the base NixOS config from the Orbstack-managed file
  imports = [
    /etc/nixos/configuration.nix
  ];

  # Stylix inherits base16Scheme from modules/stylix/default.nix (via hosts/default.nix)

  system.stateVersion = "25.11";
}
