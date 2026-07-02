{ homebrew, ... }:
let
  inherit (homebrew) brews casks masApps;
in
{
  # ============================================================================
  # Per-Host Homebrew Packages
  # ============================================================================
  # These merge with the base Homebrew config from base.nix.
  # Use with lib.mkAfter or lib.mkMerge if you want override behavior.
  # Currently this replaces the base values — we list shared casks in base.nix
  # and per-host additions here.

  homebrew = {
    inherit brews casks masApps;
  };
}
