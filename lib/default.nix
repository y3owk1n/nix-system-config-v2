{
  inputs,
  lib,
  ...
}:
let
  inherit (builtins) removeAttrs;

  # ── Host Metadata ───────────────────────────────────────────────────────────
  # Single source of truth for all per-host values
  hosts = import ../hosts;

  # Strip self from inputs for specialArgs (avoids infinite recursion)
  baseSpecialArgs = (removeAttrs inputs [ "self" ]) // {
    inherit inputs;
  };

  # ── Home-Manager Shared Config ──────────────────────────────────────────────
  mkHomeShared =
    {
      username,
      useremail,
      hostname,
      githubuser,
      githubname,
      gpgkeyid,
      needsNixGL ? false,
      stylixTheme,
    }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
      };
      home-manager.extraSpecialArgs = baseSpecialArgs // {
        inherit
          username
          useremail
          hostname
          githubuser
          githubname
          gpgkeyid
          needsNixGL
          stylixTheme
          ;
      };
    };

  # ── Home-Manager Profile Imports ──────────────────────────────────────────
  mkHomeImports =
    {
      username,
      hostData,
    }:
    let
      inherit (hostData) homeProfiles;
      profileModule = name: ../modules/home/profiles + "/${name}.nix";
    in
    {
      home-manager.users.${username} = {
        imports = [
          ../modules/home/base.nix

          # Flake input home-manager modules
          inputs.mimi.homeManagerModules.default
          inputs.neru.homeManagerModules.default
          inputs.nvs.homeManagerModules.default
          inputs.uts.homeManagerModules.default
        ]
        ++ (map profileModule homeProfiles);
      };
    };

  # ── Build a Darwin System ──────────────────────────────────────────────────
  mkDarwinSystem =
    hostName:
    let
      hostData = hosts.${hostName};
      inherit (hostData)
        system
        username
        useremail
        hostname
        githubuser
        githubname
        gpgkeyid
        stylixTheme
        safariWorkspaces
        ;
    in
    inputs.darwin.lib.darwinSystem {
      inherit system;
      specialArgs = baseSpecialArgs // {
        inherit
          username
          useremail
          hostname
          githubuser
          githubname
          gpgkeyid
          stylixTheme
          safariWorkspaces
          ;
      };
      modules = [
        ../modules/darwin/base.nix
        ../modules/darwin/defaults.nix
        ../modules/darwin/nix.nix
        ../modules/darwin/karabiner.nix
        ../modules/darwin/tailscale.nix

        # Stylix
        inputs.stylix.darwinModules.stylix
        ../modules/stylix/default.nix

        # Overlays
        { nixpkgs.overlays = [ inputs.self.overlays.default ]; }

        # Home-manager
        inputs.home-manager.darwinModules.home-manager
        (mkHomeShared {
          inherit
            username
            useremail
            hostname
            githubuser
            githubname
            gpgkeyid
            stylixTheme
            ;
        })
        (mkHomeImports { inherit username hostData; })

        # Determinate Nix
        inputs.determinate.darwinModules.default
      ]
      ++ hostData.darwinModules or [ ];
    };

  # ── Build a NixOS System ───────────────────────────────────────────────────
  mkNixosSystem =
    hostName:
    let
      hostData = hosts.${hostName};
      inherit (hostData)
        system
        username
        useremail
        hostname
        githubuser
        githubname
        gpgkeyid
        stylixTheme
        ;
      nixosProfile = ../profiles/nixos + "/${hostData.nixosProfile}.nix";
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = baseSpecialArgs // {
        inherit
          username
          useremail
          hostname
          githubuser
          githubname
          gpgkeyid
          stylixTheme
          ;
      };
      modules = [
        ../modules/nixos/base.nix
        nixosProfile

        # Overlays
        { nixpkgs.overlays = [ inputs.self.overlays.default ]; }

        # Stylix
        inputs.stylix.nixosModules.stylix
        ../modules/stylix/default.nix

        # Home-manager
        inputs.home-manager.nixosModules.home-manager
        (mkHomeShared {
          inherit
            username
            useremail
            hostname
            githubuser
            githubname
            gpgkeyid
            stylixTheme
            ;
        })
        (mkHomeImports { inherit username hostData; })
      ]
      ++ hostData.nixosModules or [ ];
    };

  # ── Filter hosts by type ──────────────────────────────────────────────────
  filterHosts = type: lib.filterAttrs (_: v: v.type == type) hosts;
in
{
  # ── Flake Outputs ──────────────────────────────────────────────────────────

  flake = {
    # Darwin configurations
    darwinConfigurations = builtins.mapAttrs (name: _: mkDarwinSystem name) (filterHosts "darwin");

    # NixOS configurations
    nixosConfigurations = builtins.mapAttrs (name: _: mkNixosSystem name) (filterHosts "nixos");

    # Standalone home-manager configurations
    homeConfigurations = builtins.mapAttrs (
      _name: hostData:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          inherit (hostData) system;
          config.allowUnfree = true;
        };
        extraSpecialArgs = baseSpecialArgs // {
          inherit (hostData)
            username
            useremail
            hostname
            githubuser
            githubname
            gpgkeyid
            needsNixGL
            stylixTheme
            ;
        };
        modules = [
          { nixpkgs.overlays = [ inputs.self.overlays.default ]; }
          ../modules/home/base.nix
          inputs.stylix.homeModules.stylix
          ../modules/stylix/default.nix

          # Flake input home-manager modules
          inputs.neru.homeManagerModules.default
          inputs.nvs.homeManagerModules.default
        ]
        ++ (map (p: ../modules/home/profiles + "/${p}.nix") hostData.homeProfiles);
      }
    ) (filterHosts "home-manager");

    # Reusable home-manager shared module (for external use)
    homeModules.shared = mkHomeShared;
  };
}
