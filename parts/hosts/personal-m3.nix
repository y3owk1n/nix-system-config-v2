{
  inputs,
  ...
}:

# ============================================================================
# Personal MacBook Air M3 Configuration
# ============================================================================
# This is the configuration for my personal MacBook Air M3 laptop.
# Used for development, personal projects, and daily computing.

let
  systemConfig = system: {
    inherit system;
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  };

  hostname = "Kyles-MacBook-Air";
  username = "kylewong";
  useremail = "62775956+y3owk1n@users.noreply.github.com"; # only used for git
  githubuser = "y3owk1n";
  githubname = "Kyle Wong";
  gpgkeyid = "F3EBDBB90E035E02";

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
    ../../darwin/hosts/personal-m3.nix
    {
      nixpkgs.overlays = [ inputs.self.overlays.default ];
    }

    # stylix
    inputs.stylix.darwinModules.stylix

    # neru
    # inputs.neru.darwinModules.default

    # home-manager
    inputs.home-manager.darwinModules.home-manager
    (inputs.self.homeModules.shared {
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
          ../../home-manager/hosts/personal-m3.nix
          # neru
          inputs.neru.homeManagerModules.default
          # nvs
          inputs.nvs.homeManagerModules.default
          # rift custom
          ../../home-manager/custom-modules/rift.nix
          # glide custom
          ../../home-manager/custom-modules/glide-wm.nix
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
