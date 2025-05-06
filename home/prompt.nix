{ ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableTransience = true;
    settings = {
      format = "$directory$custom$all";
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
        only_attached = true;
      };
      git_commit = {
        disabled = true;
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
      git_metrics = {
        disabled = false;
      };
      custom = {
        jj-custom = {
          ignore_timeout = true;
          description = "The current jj status";
          detect_folders = [ ".jj" ];
          when = "jj root --ignore-working-copy";
          symbol = "jj ";
          command = ''
            jj log --revisions @ --no-graph --ignore-working-copy --color always --limit 1 --template '
            	separate(
            		" ",
            		change_id.shortest(6),
            		bookmarks.map(|x| if(
            			x.name().substr(0, 20).starts_with(x.name()),
            			x.name().substr(0, 20),
            			x.name().substr(0, 19) ++ "…")
            		).join(" "),
            		if(
            			description.first_line().substr(0, 24).starts_with(description.first_line()),
            			description.first_line().substr(0, 24),
            			description.first_line().substr(0, 23) ++ "…"
            		),
            		if(conflict, ""),
            		if(divergent, ""),
            		if(hidden, ""),
            		if(immutable, ""),
            	)
            '
          '';
          format = "[$symbol](blue bold)$output ";
        };
      };
    };
  };
}
