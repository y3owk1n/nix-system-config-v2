{
  pkgs,
  username,
  config,
  ...
}:
let
  safariKeys = {
    "New Traworld Window" = "^4";
    "New SKBA Window" = "^3";
    "New MDA Window" = "^2";
    "New Kyle Window" = "^1";
  };
in
{
  imports = [
    # ../modules/aerospace.nix
    ../modules/cmd.nix
    ../modules/karabiner.nix
    ../modules/skhd.nix
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
  # aerospace = {
  #   enable = true;
  #   package = (
  #     pkgs.aerospace.overrideAttrs (o: rec {
  #       version = "0.19.2-Beta";
  #       src = pkgs.fetchzip {
  #         url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
  #         sha256 = "sha256-6RyGw84GhGwULzN0ObjsB3nzRu1HYQS/qoCvzVWOYWQ=";
  #       };
  #     })
  #   );
  # };

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
      "blender"
      "tailscale-app"
      "ghostty"
      "rustdesk"
      "brave-browser"
      "zen"
      "orbstack"
      # "raycast"
      "onyx"
      "imageoptim"
      "whatsapp"
      "keka"
      "appcleaner"
      "homerow"
      # "adobe-creative-cloud"
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
