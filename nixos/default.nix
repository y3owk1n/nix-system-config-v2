{
  inputs,
  nixpkgs,
  home-manager,
  catppuccin,
  nixos-npm-ls,
  ...
}:

let
  systemConfig = system: {
    system = system;
  };
in
{

  # Work
  "nixos-vm-work" =
    let
      hostname = "nixos-vm";
      username = "kylewong";
      useremail = "140996996+mtraworld@users.noreply.github.com";
      githubuser = "mtraworld";
      githubname = "mtraworld";

      inherit (systemConfig "aarch64-linux") system;
    in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = inputs // {
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
        /etc/nixos/configuration.nix
        ./hosts/work-imac.nix
        ./shared/overlays.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = inputs // {
            inherit
              username
              useremail
              hostname
              githubuser
              githubname
              ;
          };
          home-manager.users.${username} = {
            imports = [
              ../home-manager/default-nixos.nix
              # catppuccin global
              catppuccin.homeModules.catppuccin
            ];
          };
        }
      ];
    };
  # personal
  "nixos-vm-personal" =
    let
      hostname = "nixos-vm";
      username = "kylewong";
      useremail = "62775956+y3owk1n@users.noreply.github.com"; # only used for git
      githubuser = "y3owk1n";
      githubname = "Kyle Wong";

      inherit (systemConfig "aarch64-linux") system;
    in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = inputs // {
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
        /etc/nixos/configuration.nix
        ./hosts/personal-m3.nix
        ./shared/overlays.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = inputs // {
            inherit
              username
              useremail
              hostname
              githubuser
              githubname
              ;
          };
          home-manager.users.${username} = {
            imports = [
              ../home-manager/default-nixos.nix
              # catppuccin global
              catppuccin.homeModules.catppuccin
            ];
          };
        }
      ];
    };

}
