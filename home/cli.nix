{ pkgs, ... }:
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
            rev = "d3feec47b16a8e99eabb34cdfbaa115541d374fc";
            sha256 = "sha256-s0CHTihXlBMCKmbBBb8dUhfgOOQu9PBCQ+uviy7o47w=";
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
      icons = true;
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
}
