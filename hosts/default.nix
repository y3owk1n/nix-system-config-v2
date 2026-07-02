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
  #   safariWorkspaces: Safari "New Window" keybindings (for Darwin)
  #   homebrew: Per-host Homebrew formulae/casks (for Darwin)
  # ============================================================================

  # ── Personal MacBook Air M3 ─────────────────────────────────────────────────
  "Kyles-MacBook-Air" = {
    system = "aarch64-darwin";
    username = "kylewong";
    useremail = "62775956+y3owk1n@users.noreply.github.com";
    hostname = "Kyles-MacBook-Air";
    githubuser = "y3owk1n";
    githubname = "Kyle Wong";
    gpgkeyid = "F3EBDBB90E035E02";
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
        "orbstack"
        "affinity"
        "brave-browser"
        "discord"
        "whatsapp"
        "firefox"
      ];
      masApps = { };
    };
  };

  # ── Work iMac ────────────────────────────────────────────────────────────────
  "Kyles-iMac" = {
    system = "aarch64-darwin";
    username = "kylewong";
    useremail = "140996996+mtraworld@users.noreply.github.com";
    hostname = "Kyles-iMac";
    githubuser = "mtraworld";
    githubname = "mtraworld";
    gpgkeyid = "B0C4C961630F3318";
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
    ];

    safariWorkspaces = {
      "New Traworld Window" = "^1";
      "New Madani TRX Window" = "^2";
    };

    homebrew = {
      brews = [ "mole" ];
      casks = [
        "tailscale-app"
        "orbstack"
        "adobe-creative-cloud"
        "helium-browser"
      ];
      masApps = { };
    };
  };

  # ── Fedora (Standalone Home-Manager) ────────────────────────────────────────
  "fedora" = {
    system = "aarch64-linux";
    username = "kylewong";
    useremail = "62775956+y3owk1n@users.noreply.github.com";
    hostname = "fedora";
    githubuser = "y3owk1n";
    githubname = "Kyle Wong";
    gpgkeyid = "F3EBDBB90E035E02";
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
  "nixos-orb" = {
    system = "aarch64-linux";
    username = "kylewong";
    useremail = "62775956+y3owk1n@users.noreply.github.com";
    hostname = "nixos-orb";
    githubuser = "y3owk1n";
    githubname = "Kyle Wong";
    gpgkeyid = "F3EBDBB90E035E02";
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
  "nixos-utm" = {
    system = "aarch64-linux";
    username = "kylewong";
    useremail = "62775956+y3owk1n@users.noreply.github.com";
    hostname = "nixos-utm";
    githubuser = "y3owk1n";
    githubname = "Kyle Wong";
    gpgkeyid = "F3EBDBB90E035E02";
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
