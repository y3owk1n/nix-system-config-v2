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
    ../modules/passx.nix
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

  # This is a custom module at ./modules/skhd.nix
  skhd = {
    enable = true;
    package = (
      pkgs.stdenv.mkDerivation rec {
        pname = "skhd-zig";
        version = "0.0.12";

        src = pkgs.fetchzip {
          url = "https://github.com/jackielii/skhd.zig/releases/download/v${version}/skhd-arm64-macos.tar.gz";
          sha256 = "sha256-qJt2wWfM7YYVfWPbaGJ5w2LbWDhhN2MBvs+m0PCeLqM=";
          stripRoot = false;
        };

        phases = [ "installPhase" ];

        dontBuild = true; # nothing to compile

        installPhase = ''
          mkdir -p $out/bin
          cp $src/skhd-arm64-macos $out/bin/skhd
          chmod +x $out/bin/skhd
        '';
      }
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
      "blender"
      "tailscale-app"
      # "ghostty"
      "ghostty@tip"
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
