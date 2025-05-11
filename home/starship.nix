{ ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableTransience = true;
    settings = {
      command_timeout = 1000;
      palette = "catppuccin_macchiato";
      palettes = {
        catppuccin_macchiato = {
          rosewater = "#f4dbd6";
          flamingo = "#f0c6c6";
          pink = "#f5bde6";
          mauve = "#c6a0f6";
          red = "#ed8796";
          maroon = "#ee99a0";
          peach = "#f5a97f";
          yellow = "#eed49f";
          green = "#a6da95";
          teal = "#8bd5ca";
          sky = "#91d7e3";
          sapphire = "#7dc4e4";
          blue = "#8aadf4";
          lavender = "#b7bdf8";
          text = "#cad3f5";
          subtext1 = "#b8c0e0";
          subtext0 = "#a5adcb";
          overlay2 = "#939ab7";
          overlay1 = "#8087a2";
          overlay0 = "#6e738d";
          surface2 = "#5b6078";
          surface1 = "#494d64";
          surface0 = "#363a4f";
          base = "#24273a";
          mantle = "#1e2030";
          crust = "#181926";
        };
      };
      character = {
        error_symbol = "[](bold red)";
        success_symbol = "[](bold green)";
        vimcmd_replace_one_symbol = "[](bold purple)";
        vimcmd_replace_symbol = "[](bold purple)";
        vimcmd_symbol = "[](bold green)";
        vimcmd_visual_symbol = "[](bold yellow)";

      };
      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style) ";
      };
      git_metrics = {
        disabled = false;
      };
      git_status = {
        ahead = "⇡$count";
        behind = "⇣$count";
        deleted = "✘$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        modified = "!$count";
        renamed = "»$count";
        staged = "+$count";
        stashed = "\\$$count";
        untracked = "?$count";
      };
    };
  };
}
