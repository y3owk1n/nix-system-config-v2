{
  username,
  hostname,
  pkgs,
  config,
  homebrew-core,
  homebrew-cask,
  homebrew-bundle,
  homebrew-y3owk1n,
  ...
}:
{
  # ============================================================================
  # Networking
  # ============================================================================

  networking = {
    hostName = hostname;
    computerName = hostname;
    applicationFirewall = {
      enable = true;
      blockAllIncoming = false;
      enableStealthMode = true;
      allowSignedApp = true;
      allowSigned = true;
    };
  };

  # ============================================================================
  # Users
  # ============================================================================

  users.users."${username}" = {
    uid = 501;
    home = "/Users/${username}";
    description = username;
    shell = pkgs.fish;
  };

  users.knownUsers = [ "${username}" ];

  # ============================================================================
  # Environment
  # ============================================================================

  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  environment.systemPackages = with pkgs; [
    coreutils
  ];

  # ============================================================================
  # Security
  # ============================================================================

  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  # ============================================================================
  # nix-homebrew — manages Homebrew taps declaratively
  # ============================================================================

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    taps = {
      "homebrew/homebrew-core" = homebrew-core;
      "homebrew/homebrew-cask" = homebrew-cask;
      "homebrew/homebrew-bundle" = homebrew-bundle;
      "y3owk1n/homebrew-tap" = homebrew-y3owk1n;
    };
    mutableTaps = false;
  };

  # ============================================================================
  # Homebrew - base config
  # ============================================================================

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    taps = builtins.attrNames config.nix-homebrew.taps;
  };

  # ============================================================================
  # Time Zone
  # ============================================================================

  time.timeZone = "Asia/Kuala_Lumpur";

  # ============================================================================
  # Fonts
  # ============================================================================

  fonts = {
    packages = with pkgs; [
      poppins
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
    ];
  };

  # ============================================================================
  # Launch Daemons
  # ============================================================================

  launchd = {
    daemons = {
      "limits.maxfile" = {
        serviceConfig = {
          Label = "limits.maxfile";
          ProgramArguments = [
            "/bin/launchctl"
            "limit"
            "maxfiles"
            "524288"
            "524288"
          ];
          RunAtLoad = true;
          ServiceIPC = false;
        };
      };
      "limits.maxproc" = {
        serviceConfig = {
          Label = "limits.maxproc";
          ProgramArguments = [
            "/bin/launchctl"
            "limit"
            "maxproc"
            "2048"
            "2048"
          ];
          RunAtLoad = true;
          ServiceIPC = false;
        };
      };
    };
  };
}
