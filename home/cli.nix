{ pkgs, ... }:
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
        "--style full"
        "--layout reverse"
        "--tmux center"
      ];
      fileWidgetCommand = "fd --exclude .git --type f"; # for when ctrl-t is pressed
      changeDirWidgetCommand = "fd --type d --hidden --follow --max-depth 3 --exclude .git";
    };

    # Better top
    btop = {
      enable = true;
      settings = {
        color_theme = "catppuccin_macchiato";
      };
      themes = {
        catppuccin_macchiato = ''
          # Main background, empty for terminal default, need to be empty if you want transparent background
          theme[main_bg]="#24273a"

          # Main text color
          theme[main_fg]="#cad3f5"

          # Title color for boxes
          theme[title]="#cad3f5"

          # Highlight color for keyboard shortcuts
          theme[hi_fg]="#8aadf4"

          # Background color of selected item in processes box
          theme[selected_bg]="#494d64"

          # Foreground color of selected item in processes box
          theme[selected_fg]="#8aadf4"

          # Color of inactive/disabled text
          theme[inactive_fg]="#8087a2"

          # Color of text appearing on top of graphs, i.e uptime and current network graph scaling
          theme[graph_text]="#f4dbd6"

          # Background color of the percentage meters
          theme[meter_bg]="#494d64"

          # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
          theme[proc_misc]="#f4dbd6"

          # CPU, Memory, Network, Proc box outline colors
          theme[cpu_box]="#c6a0f6" #Mauve
          theme[mem_box]="#a6da95" #Green
          theme[net_box]="#ee99a0" #Maroon
          theme[proc_box]="#8aadf4" #Blue

          # Box divider line and small boxes line color
          theme[div_line]="#6e738d"

          # Temperature graph color (Green -> Yellow -> Red)
          theme[temp_start]="#a6da95"
          theme[temp_mid]="#eed49f"
          theme[temp_end]="#ed8796"

          # CPU graph colors (Teal -> Lavender)
          theme[cpu_start]="#8bd5ca"
          theme[cpu_mid]="#7dc4e4"
          theme[cpu_end]="#b7bdf8"

          # Mem/Disk free meter (Mauve -> Lavender -> Blue)
          theme[free_start]="#c6a0f6"
          theme[free_mid]="#b7bdf8"
          theme[free_end]="#8aadf4"

          # Mem/Disk cached meter (Sapphire -> Lavender)
          theme[cached_start]="#7dc4e4"
          theme[cached_mid]="#8aadf4"
          theme[cached_end]="#b7bdf8"

          # Mem/Disk available meter (Peach -> Red)
          theme[available_start]="#f5a97f"
          theme[available_mid]="#ee99a0"
          theme[available_end]="#ed8796"

          # Mem/Disk used meter (Green -> Sky)
          theme[used_start]="#a6da95"
          theme[used_mid]="#8bd5ca"
          theme[used_end]="#91d7e3"

          # Download graph colors (Peach -> Red)
          theme[download_start]="#f5a97f"
          theme[download_mid]="#ee99a0"
          theme[download_end]="#ed8796"

          # Upload graph colors (Green -> Sky)
          theme[upload_start]="#a6da95"
          theme[upload_mid]="#8bd5ca"
          theme[upload_end]="#91d7e3"

          # Process box color gradient for threads, mem and cpu usage (Sapphire -> Mauve)
          theme[process_start]="#7dc4e4"
          theme[process_mid]="#b7bdf8"
          theme[process_end]="#c6a0f6"
        '';
      };
    };
  };

}
