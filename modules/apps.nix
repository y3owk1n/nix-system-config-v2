{ pkgs, username, ... }:
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
    enable = false;
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
    masApps = {
      # --- when want to use safari ---
      # "Wappalyzer" = 1520333300;
      "AdGuard for Safari" = 1440147259;
      # "Consent-O-Matic" = 1606897889;
      # "JSON Peep for Safari" = 1458969831;
      # "Vimlike" = 1584519802;
      "Customize Search Engine" = 6445840140;

      # --- misc ---
      "Tailscale" = 1475387142;
    };

    taps = [
      "homebrew/services"
      "y3owk1n/tap"
    ];

    # `brew install`
    brews = [
      "kanata"
      "y3owk1n/tap/cpenv"
    ];

    # `brew install --cask`
    casks = [
      "onyx"
      "imageoptim"
      "whatsapp"
      "zerotier-one"
      "pronotes"
      "hammerspoon" # mainly used for safari vim mode

      "ghostty"
      # "alacritty"

      # --- docker desktop alternative ---
      "orbstack"

      # --- browser ---
      # "brave-browser"
      # "zen-browser"
    ];
  };
}
