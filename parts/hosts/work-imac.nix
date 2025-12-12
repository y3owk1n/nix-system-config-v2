{
  inputs,
  ...
}:

let
  systemConfig = system: {
    inherit system;
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  };

  hostname = "Kyles-iMac";
  username = "kylewong";
  useremail = "140996996+mtraworld@users.noreply.github.com";
  githubuser = "mtraworld";
  githubname = "mtraworld";
  gpgkeyid = "B0C4C961630F3318";

  inherit (systemConfig "aarch64-darwin") system;
in
inputs.darwin.lib.darwinSystem {
  inherit system;
  specialArgs = (builtins.removeAttrs inputs [ "self" ]) // {
    inherit
      system
      username
      useremail
      hostname
      githubuser
      githubname
      ;
  };
  modules = [
    ../../darwin/hosts/work-imac.nix
    {
      nixpkgs.overlays = [ inputs.self.overlays.default ];
    }

    # stylix
    inputs.stylix.darwinModules.stylix

    # home-manager
    inputs.home-manager.darwinModules.home-manager
    (inputs.self.homeManagerModules.shared {
      inherit
        username
        useremail
        hostname
        githubuser
        githubname
        gpgkeyid
        ;
    })
    {
      home-manager.users.${username} = {
        imports = [
          ../../home-manager/shared/base.nix
          ../../home-manager/hosts/work-imac.nix
          # neru
          inputs.neru.homeManagerModules.default
          # nvs
          inputs.nvs.homeManagerModules.default
          # rift custom
          ../../home-manager/custom/rift.nix
        ];
      };
    }

    # determinate
    inputs.determinate.darwinModules.default

    # Homebrew
    inputs.nix-homebrew.darwinModules.nix-homebrew
    (import ../../darwin/shared/nix-homebrew.nix {
      inherit username;
      inherit (inputs)
        homebrew-core
        homebrew-cask
        homebrew-bundle
        homebrew-y3owk1n
        ;
    })
  ];
}
