# Nix System Configuration

System configuration for multiple machines using Nix flakes, nix-darwin, NixOS, and Home-Manager. Hosts are defined in one place. Builders assemble the full system from host data, profiles, and platform modules.

## Language

**Host**:
A named machine configuration (e.g. `Kyles-MacBook-Air`, `fedora`). Each host declares its system type, username, and which profiles to activate.
_Avoid_: machine, node, box

**Profile**:
A named group of Home-Manager package modules (e.g. `cli`, `shell`, `git`). Profiles are imported by hosts to compose the set of installed programs.
_Avoid_: bundle, collection, group

**Builder**:
A function in `lib/default.nix` that assembles a complete system configuration from host data, profiles, and platform modules. `mkDarwinSystem`, `mkNixosSystem`, and `homeConfigurations` are all builders.
_Avoid_: factory, constructor, generator

**specialArgs**:
The per-host values (username, hostname, email, etc.) threaded into all NixOS, darwin, and Home-Manager modules via `extraSpecialArgs`. The single source of truth is `hosts/default.nix`.
_Avoid_: args, context, config

**Platform**:
The OS-specific derivation choices controlled by `pkgs.stdenv.hostPlatform.isDarwin` / `isLinux`. Determines package variants, path prefixes, and feature flags.
_Avoid_: system, arch, target

**Custom package**:
A derivation in `pkgs/custom/` not available in nixpkgs. Built via `fetchurl` or `fetchzip` and exposed through the overlay as `pkgs.custom.<name>`.
\_Avoid\*: overlay package, local package

**Common package**:
A consolidated Home-Manager module that groups several simple program enables (e.g. `common-cli.nix` for the cli profile). One file replaces many single-line files.
_Avoid_: trivial module, thin wrapper

**follows**:
A flake input directive that deduplicates transitive dependencies by pointing them at a shared input (e.g. `inputs.nixpkgs.follows = "nixpkgs"`). Prevents multiple nixpkgs evaluations and version mismatches.
_Avoid_: pin, redirect

**sharedModules**:
A nix-darwin option (`home-manager.sharedModules`) that injects Home-Manager modules into every user declared in the configuration. Used for settings that should apply universally rather than per-user.
_Avoid_: common modules, global modules

**perSystem**:
A flake-parts attribute that declares system-specific outputs (packages, checks, formatters) evaluated once per system in the systems list. Keeps per-platform logic out of the top-level flake outputs.
_Avoid_: system outputs, per-platform
