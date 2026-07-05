{
  username,
  hostname,
  pkgs,
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
