{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting\n

      # Disable Fish's native history by using a dummy session
      set -x fish_history ""

      if type -q nvs
        nvs env --source | source
      end

    '';
    shellInit = ''
      __load-em
      __autols_hook
      # starship_transient_prompt_func
      setup_tide
    '';
    shellAliases = {
      gg = "lazygit";
      c = "clear";
      x = "exit";
      cat = "bat";
      tx = "tmux kill-server";
      vim = "nvim";
    };
    plugins = [
      {
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
          repo = "tide";
          rev = "v6.2.0";
          sha256 = "sha256-1ApDjBUZ1o5UyfQijv9a3uQJ/ZuQFfpNmHiDWzoHyuw=";
        };
      }
    ];
    functions = {
      __load-em = {
        description = "Loads Fish shell function descriptions.";
        body = ''
          # Load function information so it shows up in auto completion
          # Original from https://github.com/fish-shell/fish-shell/issues/1915#issuecomment-72315918

          for i in (functions | tr , ' ')
              functions $i > /dev/null
          end
        '';
      };
      fish_user_key_bindings = ''
        fish_vi_key_bindings
      '';
      __autols_hook = {
        description = "Auto ls";
        onVariable = "PWD";
        body = ''
          if not set -q __autols_initialized
              set -g __autols_initialized 1
              return
          end

          if test "$PWD" != "$__autols_last"
              echo
              ls
              set -g __autols_last $PWD
          end
        '';
      };
      starship_transient_prompt_func = {
        description = "Starship transient prompt";
        body = ''
          starship module character
        '';
      };
      setup_tide = {
        description = "Setup tide";
        body = ''
          if not set -q tide_configured
              tide configure --auto --style=Lean --prompt_colors='16 colors' --show_time=No --lean_prompt_height='Two lines' --prompt_connection=Disconnected --prompt_spacing=Sparse --icons='Many icons' --transient=Yes

              # Set a universal flag so we don't run again
              # use `set -eU tide_configured` to reset
              set -U tide_configured true
          end

          set -U tide_character_icon 
          set -U tide_character_vi_icon_default 
          set -U tide_character_vi_icon_replace 
          set -U tide_character_vi_icon_visual 
          set -U tide_git_icon 
          set -U tide_git_color_branch magenta
          set -U tide_status_icon 
          set -U tide_status_icon_failure 
        '';
      };
    };
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    SHELL = "${pkgs.fish}/bin/fish";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    TERM = "xterm-256color";
    KEYTIMEOUT = 1;
    EDITOR = "nvim";
    VISUAL = "nvim";
    GIT_EDITOR = "nvim";
    SYSTEMD_COLORS = "true";
    COLORTERM = "truecolor";
    TERMINAL = "ghostty";
    # HOMEBREW_NO_AUTO_UPDATE = 1;
    PAGER = "less";
    LESS = "-R";
    CLICOLOR = 1;
  };
}
