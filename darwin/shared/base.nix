# This are the base settings for all hosts
{
  username,
  config,
  pkgs,
  hostname,
  ...
}:
{
  system.defaults.smb.NetBIOSName = hostname;

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

  users.users."${username}" = {
    uid = 501;
    home = "/Users/${username}";
    description = username;
    shell = pkgs.fish;
  };

  users.knownUsers = [ "${username}" ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  environment.systemPackages = with pkgs; [
    coreutils
    # install GUI apps via nix darwin so that we can get spotlight indexing
    ghostty-bin # this is the darwin version, `ghostty` is for linux only
  ];

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local = {
    enable = true;
    reattach = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "zap";
    };

    # Need to add the configured taps from `nix-homebrew`
    # https://github.com/zhaofengli/nix-homebrew/issues/5#issuecomment-1878798641
    taps = builtins.attrNames config.nix-homebrew.taps;

    brews = [ ];

    casks = [
      "tailscale-app"
      "rustdesk"
      "helium-browser"
      "zen"
      "orbstack"
      "appcleaner"
      "whatsapp"
      "imageoptim"
      "onyx"
      "homerow"
    ];

    masApps = { };
  };

  # Set your time zone.
  time.timeZone = "Asia/Kuala_Lumpur";

  # Fonts
  fonts = {
    packages = with pkgs; [
      poppins
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
    ];
  };

  stylix = {
    enable = true;
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
    base16Scheme = ../../config/pastel-twilight/base16.yml;
  };

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
