_: {
  # ============================================================================
  # Personal MacBook Air M3 - Darwin Profile
  # ============================================================================

  # Per-host homebrew additions (shared casks are in modules/darwin/base.nix)
  # Homebrew casks defined here per-host via hosts/default.nix -> homebrew field
  # which is handled by the modules/darwin/homebrew.nix module.

  hammerspoon = {
    enable = false;
  };
}
