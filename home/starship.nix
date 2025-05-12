{ ... }:
{
  programs.starship = {
    enable = true;
    enableTransience = true;
    settings = {
      command_timeout = 1000;
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
