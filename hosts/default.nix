let
  # ── Shared Defaults ─────────────────────────────────────────────────────────
  defaults = {
    username = "kylewong";
    useremail = "62775956+y3owk1n@users.noreply.github.com";
    githubuser = "y3owk1n";
    githubname = "Kyle Wong";
    gpgkeyid = "F3EBDBB90E035E02";
    stylixTheme = ../config/colorschemes/forest-ink/base16.yml;
  };
in
{
  # ============================================================================
  # Centralized Host Metadata
  # ============================================================================
  # Single source of truth for all host-specific configuration values.
  # Each host in this attrset gets auto-discovered by the lib builder functions.
  #
  # Fields:
  #   system:     Nix system string (e.g. "aarch64-darwin")
  #   username:   Local username
  #   useremail:  Git commit email
  #   hostname:   System hostname
  #   githubuser: GitHub username
  #   githubname: Display name for git
  #   gpgkeyid:   GPG signing key
  #   type:       "darwin" | "nixos" | "home-manager"
  #   homeProfiles: List of home-manager profile names to enable
  #   darwinModules: Extra darwin module paths (optional)
  #   nixosModules:  Extra NixOS module paths (optional)
  #   nixosProfile: Name of NixOS profile (for type = "nixos")
  #   needsNixGL: Whether nixGL wrapping is needed (for Linux)
  #   stylixTheme: Path to base16 theme YAML (shared across all hosts)
  #   safariWorkspaces: Safari "New Window" keybindings (for Darwin)
  #   homebrew: Per-host Homebrew formulae/casks (for Darwin)
  # ============================================================================

  # ── Personal MacBook Air M3 ─────────────────────────────────────────────────
  "Kyles-MacBook-Air" = defaults // {
    system = "aarch64-darwin";
    hostname = "Kyles-MacBook-Air";
    type = "darwin";
    needsNixGL = false;

    homeProfiles = [
      "cli"
      "shell"
      "git"
      "editors"
      "security"
      "terminal"
      "macos"
      "ai"
      "messaging"
    ];

    safariWorkspaces = {
      "New Wakesport Window" = "^6";
      "New Madani TRX Window" = "^5";
      "New Traworld Window" = "^4";
      "New SKBA Window" = "^3";
      "New MDA Window" = "^2";
      "New Kyle Window" = "^1";
    };

    homebrew = {
      brews = [ "mole" ];
      casks = [
        "tailscale-app"
        "affinity"
        "brave-browser"
        "firefox"
      ];
      masApps = { };
    };
  };

  # ── Fedora (Standalone Home-Manager) ────────────────────────────────────────
  "fedora" = defaults // {
    system = "aarch64-linux";
    hostname = "fedora";
    type = "home-manager";
    needsNixGL = true;

    homeProfiles = [
      "cli"
      "shell"
      "git"
      "editors"
      "security"
      "terminal"
      "ai"
    ];
  };

  # ── NixOS Orbstack VM ───────────────────────────────────────────────────────
  "nixos-orb" = defaults // {
    system = "aarch64-linux";
    hostname = "nixos-orb";
    type = "nixos";
    needsNixGL = false;
    nixosProfile = "orb";

    homeProfiles = [
      "cli"
      "shell"
      "git"
      "editors"
      "security"
      "ai"
    ];
  };

  # ── NixOS UTM VM ────────────────────────────────────────────────────────────
  "nixos-utm" = defaults // {
    system = "aarch64-linux";
    hostname = "nixos-utm";
    type = "nixos";
    needsNixGL = false;
    nixosProfile = "utm";

    homeProfiles = [
      "cli"
      "shell"
      "git"
      "editors"
      "security"
      "terminal"
      "ai"
    ];
  };
}
