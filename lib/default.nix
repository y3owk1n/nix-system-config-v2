{
  inputs,
  lib,
  ...
}:
let
  inherit (builtins) removeAttrs;

  # ── Host Metadata ───────────────────────────────────────────────────────────
  # All per-host values live here
  hosts = import ../hosts;

  # Strip self from inputs for specialArgs (avoids infinite recursion)
  baseSpecialArgs = (removeAttrs inputs [ "self" ]) // {
    inherit inputs;
  };

  # ── Host Field Extraction ───────────────────────────────────────────────────
  # Destructure once — every builder and mkHomeShared reads from here
  hostFields =
    hostData:
    let
      inherit (hostData)
        username
        useremail
        hostname
        githubuser
        githubname
        gpgkeyid
        stylixTheme
        ;
    in
    {
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

  # ── Home-Manager Profile Imports (NixOS / Darwin) ────────────────────────
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
          inputs.agent-skills.homeManagerModules.default
        ]
        ++ (map profileModule homeProfiles);
      };
    };

  # ── Home-Manager Profile Imports (Standalone) ────────────────────────────
  mkStandaloneImports =
    { hostData }:
    let
      inherit (hostData) homeProfiles;
      profileModule = name: ../modules/home/profiles + "/${name}.nix";
    in
    [
      ../modules/home/base.nix

      # Flake input home-manager modules
      inputs.mimi.homeManagerModules.default
      inputs.neru.homeManagerModules.default
      inputs.nvs.homeManagerModules.default
      inputs.uts.homeManagerModules.default
      inputs.agent-skills.homeManagerModules.default
    ]
    ++ (map profileModule homeProfiles);

  # ── Shared module sets ────────────────────────────────────────────────────
  overlayModule = {
    nixpkgs.overlays = [ inputs.self.overlays.default ];
  };

  stylixModules =
    { type }:
    let
      stylix =
        if type == "darwin" then
          inputs.stylix.darwinModules.stylix
        else if type == "nixos" then
          inputs.stylix.nixosModules.stylix
        else
          inputs.stylix.homeModules.stylix;
    in
    [
      stylix
      ../modules/stylix/default.nix
    ];

  hmModule =
    { type }:
    if type == "darwin" then
      inputs.home-manager.darwinModules.home-manager
    else if type == "nixos" then
      inputs.home-manager.nixosModules.home-manager
    else
      inputs.home-manager.lib.homeManagerConfiguration;

  # ── System Builder ──────────────────────────────────────────────────────
  mkSystem =
    {
      hostName,
      type,
      extraModules ? [ ],
    }:
    let
      hostData = hosts.${hostName};
      fields = hostFields hostData;
      inherit (fields) username;

      homeShared = mkHomeShared {
        inherit (fields)
          username
          useremail
          hostname
          githubuser
          githubname
          gpgkeyid
          stylixTheme
          ;
        inherit (hostData) needsNixGL;
      };

      homeImports = mkHomeImports {
        inherit username hostData;
      };

      specialArgs =
        baseSpecialArgs
        // fields
        // lib.optionalAttrs (hostData ? safariWorkspaces) {
          inherit (hostData) safariWorkspaces;
        }
        // lib.optionalAttrs (hostData ? needsNixGL) {
          inherit (hostData) needsNixGL;
        };
    in
    if type == "darwin" then
      inputs.darwin.lib.darwinSystem {
        inherit (hostData) system;
        inherit specialArgs;
        modules = [
          ../modules/darwin/base.nix
          ../modules/darwin/defaults.nix
          ../modules/darwin/nix.nix
          ../modules/darwin/karabiner.nix
          ../modules/darwin/tailscale.nix
          overlayModule
          (hmModule { type = "darwin"; })
          homeShared
          homeImports
          inputs.determinate.darwinModules.default
        ]
        ++ (stylixModules { type = "darwin"; })
        ++ extraModules
        ++ (hostData.darwinModules or [ ]);
      }
    else if type == "nixos" then
      let
        nixosProfile = ../profiles/nixos + "/${hostData.nixosProfile}.nix";
      in
      inputs.nixpkgs.lib.nixosSystem {
        inherit (hostData) system;
        inherit specialArgs;
        modules = [
          ../modules/nixos/base.nix
          nixosProfile
          overlayModule
          (hmModule { type = "nixos"; })
          homeShared
          homeImports
        ]
        ++ (stylixModules { type = "nixos"; })
        ++ extraModules
        ++ (hostData.nixosModules or [ ]);
      }
    else
      # standalone home-manager
      let
        standaloneImports = mkStandaloneImports { inherit hostData; };
      in
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          inherit (hostData) system;
          config.allowUnfree = true;
        };
        extraSpecialArgs = specialArgs;
        modules = [
          overlayModule
        ]
        ++ (stylixModules { type = "home-manager"; })
        ++ standaloneImports
        ++ extraModules;
      };

  # ── Filter hosts by type ──────────────────────────────────────────────────
  filterHosts = type: lib.filterAttrs (_: v: v.type == type) hosts;
in
{
  # ── Flake Outputs ──────────────────────────────────────────────────────────

  flake = {
    # Darwin configurations
    darwinConfigurations = builtins.mapAttrs (
      name: _:
      mkSystem {
        hostName = name;
        type = "darwin";
      }
    ) (filterHosts "darwin");

    # NixOS configurations
    nixosConfigurations = builtins.mapAttrs (
      name: _:
      mkSystem {
        hostName = name;
        type = "nixos";
      }
    ) (filterHosts "nixos");

    # Standalone home-manager configurations
    homeConfigurations = builtins.mapAttrs (
      name: _:
      mkSystem {
        hostName = name;
        type = "home-manager";
      }
    ) (filterHosts "home-manager");

    # Home-manager shared module (exported for external use)
    homeModules.shared = mkHomeShared;
  };
}
