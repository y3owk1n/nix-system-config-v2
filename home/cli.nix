{ pkgs, config, ... }:
{
  programs = {
    # Prettier cat
    bat = {
      enable = true;
      config = {
        theme = "catppuccin";
        italic-text = "always";
        style = "plain"; # no line numbers, git status, etc... more like cat with colors
      };
      themes = {
        catppuccin = {
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "bat"; # Bat uses sublime syntax for its themes
            rev = "699f60fc8ec434574ca7451b444b880430319941";
            sha256 = "sha256-6fWoCH90IGumAMc4buLRWL0N61op+AuMNN9CAR9/OdI=";
          };
          file = "themes/Catppuccin Macchiato.tmTheme";
        };
      };
    };

    # A modern replacement for ‘ls’
    # useful in bash/zsh prompt, not in nushell.
    eza = {
      enable = true;
      enableFishIntegration = true;
      git = true;
      icons = "auto";
    };

    # A smarter cd command. Supports all major shells.
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    # Fuzzy finder
    fzf = {
      enable = true;
      enableFishIntegration = true;
      tmux.enableShellIntegration = true;
      colors = {
        "bg+" = "#363a4f";
        bg = "#24273a";
        spinner = "#f4dbd6";
        hl = "#ed8796";
        fg = "#cad3f5";
        header = "#ed8796";
        info = "#8aadf4";
        pointer = "#f4dbd6";
        marker = "#f4dbd6";
        "fg+" = "#cad3f5";
        prompt = "#8aadf4";
        border = "#8aadf4";
        "hl+" = "#ed8796";
        gutter = "#24273a";
      };
      defaultCommand = "fd --type f --hidden --exclude .git";
      defaultOptions = [
        "--layout reverse"
        "--height ~40%"
        "--border"
        "--tmux center"
        "--preview 'bat --color=always {}'"
      ];
      fileWidgetCommand = "fd --exclude .git --type f"; # for when ctrl-t is pressed
      changeDirWidgetCommand = "fd --type d --hidden --follow --max-depth 3 --exclude .git";
    };
  };

  # Better top
  xdg.configFile.btop = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/btop";
    recursive = true;
  };
}
