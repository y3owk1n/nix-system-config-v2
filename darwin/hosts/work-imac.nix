{
  pkgs,
  username,
  config,
  ...
}:
let
  safariKeys = {
    "New Traworld Window" = "^1";
    "New Madani TRX Window" = "^2";
  };
in
{
  imports = [
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
      "tailscale-app"
      # "ghostty"
      # "ghostty@tip"
      "rustdesk"
      "brave-browser"
      "zen"
      "orbstack"
      # "raycast"
      "onyx"
      "imageoptim"
      "whatsapp"
      "appcleaner"
      "adobe-creative-cloud"
      # "homerow"
      "hammerspoon"
      # "keyboard-cowboy"
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
}
