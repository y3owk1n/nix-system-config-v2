{
  pkgs,
  username,
  config,
  ...
}:
let
  safariKeys = {
    "New Traworld Window" = "^1";
  };
in
{
  imports = [
    ../modules/aerospace.nix
    ../modules/cmd.nix
    ../modules/karabiner.nix
    ../shared/core.nix
    (import ../shared/darwin.nix {
      inherit
        safariKeys
        pkgs
        config
        username
        ;
    })
  ];

  users.users."${username}" = {
    home = "/Users/${username}";
    description = username;
    shell = pkgs.fish;
  };

  # This is a custom module at ./modules/aerospace.nix
  aerospace = {
    enable = true;
    package = (
      pkgs.aerospace.overrideAttrs (o: rec {
        version = "0.18.5-Beta";
        src = pkgs.fetchzip {
          url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
          sha256 = "sha256-rF4emnLNVE1fFlxExliN7clSBocBrPwQOwBqRtX9Q4o=";
        };
      })
    );
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

    brews = [
      # "y3owk1n/homebrew-tap/cpenv"
      # "y3owk1n/homebrew-tap/nvs"
    ];

    casks = [
      "zerotier-one"
      "tailscale"
      "ghostty"
      "rustdesk"
      "brave-browser"
      "zen"
      "orbstack"
      "raycast"
      "onyx"
      "imageoptim"
      "whatsapp"
      "keka"
      "appcleaner"
      "adobe-creative-cloud"
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
}
