{ inputs, ... }:
{
  flake.homeConfigurations = {
    "kylewong-fedora" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.aarch64-linux;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        {
          nixpkgs.overlays = [ inputs.self.overlays.default ];
          stylix = {
            enable = true;
            base16Scheme = ../../config/pastel-twilight/base16.yml;
          };
        }
        ../../home-manager/shared/base.nix
        ../../home-manager/hosts/nixos-fedora.nix
        # nvs
        inputs.nvs.homeManagerModules.default
        # neru
        inputs.neru.homeManagerModules.default
        # stylix
        inputs.stylix.homeModules.stylix
      ];
    };
  };
}
