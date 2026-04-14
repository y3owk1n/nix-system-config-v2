{ inputs, ... }:
let
  username = "kylewong";
  useremail = "62775956+y3owk1n@users.noreply.github.com";
  hostname = "fedora";
  githubuser = "y3owk1n";
  githubname = "Kyle Wong";
  gpgkeyid = "F3EBDBB90E035E02";
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs {
    system = "aarch64-linux";
    config.allowUnfree = true;
  };
  extraSpecialArgs = (builtins.removeAttrs inputs [ "self" ]) // {
    inherit
      username
      useremail
      hostname
      githubuser
      githubname
      gpgkeyid
      ;
    needsNixGL = true;
  };
  modules = [
    {
      nixpkgs.overlays = [ inputs.self.overlays.default ];
      stylix = {
        enable = true;
        base16Scheme = ../../config/pastel-twilight/base16.yml;
      };
    }
    ../../home-manager/shared/base.nix
    ../../home-manager/hosts/fedora.nix
    inputs.nvs.homeManagerModules.default
    inputs.neru.homeManagerModules.default
    inputs.stylix.homeModules.stylix
  ];
}
