{ ... }: {
  # ============================================================================
  # NixOS Orbstack VM Profile
  # ============================================================================

  # Inherit the base NixOS config from the Orbstack-managed file
  imports = [
    /etc/nixos/configuration.nix
  ];

  # Stylix (base16Scheme set in modules/stylix/default.nix but can be overridden)
  stylix = {
    enable = true;
    base16Scheme = ../../config/colorschemes/pastel-twilight/base16.yml;
  };

  system.stateVersion = "25.11";
}
