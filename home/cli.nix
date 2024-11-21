{ pkgs, config, ... }:
{
  programs = {
    # Prettier cat
    bat = {
      enable = true;
      config = {
        theme = "catppuccin";
        pager = "page -WO -q 90000";
        italic-text = "always";
        style = "plain"; # no line numbers, git status, etc... more like cat with colors
      };
      themes = {
        catppuccin = {
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "bat"; # Bat uses sublime syntax for its themes
            rev = "d2bbee4f7e7d5bac63c054e4d8eca57954b31471";
            sha256 = "sha256-x1yqPCWuoBSx/cI94eA+AWwhiSA42cLNUOFJl7qjhmw=";
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

    # skim provides a single executable: sk.
    # Basically anywhere you would want to use grep, try sk instead.
    skim = {
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
        info = "#c6a0f6";
        pointer = "#f4dbd6";
        marker = "#f4dbd6";
        "fg+" = "#cad3f5";
        prompt = "#c6a0f6";
        "hl+" = "#ed8796";
      };
      defaultCommand = "fd --type f --hidden --exclude .git";
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
