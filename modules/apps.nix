{ pkgs, hostname, ... }:
let
  brewApps =
    if hostname == "Kyles-MacBook-Air" then
      [
        "blender"
      ]
    else if hostname == "Kyles-iMac" then
      [ "zerotier-one" ]
    else
      [ ];
in
{

  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://daiderd.com/nix-darwin/manual/index.html
  #
  #
  ##########################################################################

  # Install packages from nix's official package repository.
  #
  # The packages installed here are available to all users, and are reproducible across machines, and are rollbackable.
  # But on macOS, it's less stable than homebrew.
  #
  # Whenever is possible, install packages on home manager instead
  #
  # Related Discussion: https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    ncurses
    coreutils
  ];
  environment.variables.EDITOR = "nvim";
  environment.etc.terminfo = {
    source = "${pkgs.ncurses}/share/terminfo";
  };

  # This is a custom module at ./custom/aerospace.nix
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

  # TODO: To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "zap";
    };

    # Applications to install from Mac App Store using mas.
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them.
    # For details, see https://github.com/mas-cli/mas
    masApps = { };

    taps = [ ];

    # `brew install`
    brews = [
      "y3owk1n/tap/cpenv"
      "y3owk1n/tap/nvs"
    ];

    # `brew install --cask`
    casks = brewApps ++ [
      # --- Networking ---
      "tailscale"
      # --- terminal ---
      "ghostty"
      # --- screen sharing ---
      "rustdesk"
      # --- browsers ---
      "brave-browser"
      "zen"
      # --- docker desktop alternative ---
      "orbstack"
      # --- spotlight alternative ---
      "raycast"
      # --- misc ---
      "onyx"
      "imageoptim"
      "whatsapp"
      "keka"
      "appcleaner"
      "adobe-creative-cloud"
    ];
  };
}
