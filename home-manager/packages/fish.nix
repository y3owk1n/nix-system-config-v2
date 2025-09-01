{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting

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
      # setup_tide
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
      # Add your custom fish_prompt here
      fish_prompt = {
        description = "Custom prompt with async git status";
        body = ''
          # git configuration
          set -g __fish_git_prompt_show_informative_status 1
          set -g __fish_git_prompt_showdirtystate 1
          set -g __fish_git_prompt_showstashstate 1
          set -g __fish_git_prompt_showupstream auto
          set -g __fish_git_prompt_showuntrackedfiles 1
          set -g __fish_git_prompt_showcolorhints 1

          # git char configurations
          set -g __fish_git_prompt_char_stateseparator ' '
          set -g __fish_git_prompt_char_dirtystate '!' # modified files
          set -g __fish_git_prompt_char_stagedstate '+' # staged files
          set -g __fish_git_prompt_char_untrackedfiles '?' # untracked files
          set -g __fish_git_prompt_char_stashstate '$' # stashed files
          set -g __fish_git_prompt_char_upstream_ahead '⇡' # ahead of upstream
          set -g __fish_git_prompt_char_upstream_behind '⇣' # behind upstream
          set -g __fish_git_prompt_char_upstream_diverged '⇕' # diverged from upstream

          # async git state
          set -g __git_info ""
          set -g __git_pid ""
          set -g __git_tmpfile ""
          set -g __git_loading_indicator "…"

          function __git_cleanup
              # kill any running process
              if test -n "$__git_pid"
                  and kill -0 $__git_pid 2>/dev/null
                  kill $__git_pid 2>/dev/null
                  set -g __git_pid ""
              end
              # clean up temp file and reset state
              if test -n "$__git_tmpfile"
                  rm -f "$__git_tmpfile" 2>/dev/null
                  set -g __git_tmpfile ""
              end
          end

          function __git_check_for_changes --on-event fish_postexec
              # check if the last command was git-related
              set -l last_cmd (history --max 1 2>/dev/null | string trim)
              if string match -q "git *" "$last_cmd"
                  # trigger git info refresh
                  __git_launch
              end
          end

          function __git_launch --on-variable PWD --on-event fish_postexec
              # cancel any previous job
              __git_cleanup
              # outside a repo → clear immediately
              if not command git -C $PWD rev-parse --is-inside-work-tree &>/dev/null
                  set -g __git_info ""
                  return
              end
              # show loading indicator for slow repos
              set -g __git_info (set_color brblack)" on $__git_loading_indicator"
              # create unique temp file in more appropriate location
              set -g __git_tmpfile "/tmp/fish_git_$fish_pid"_(random)
              # start background job
              fish -c "
                  fish_git_prompt > \"$__git_tmpfile\" 2>/dev/null
                  # Signal fish to refresh by sending SIGUSR1 to parent
                  kill -USR1 $fish_pid 2>/dev/null
              " &
              set -g __git_pid $last_pid
              # disown the job so it doesn't prevent exit
              disown $__git_pid 2>/dev/null
          end

          function __git_refresh --on-signal USR1
              # check if we have git info ready
              if test -n "$__git_tmpfile"
                  and test -f "$__git_tmpfile"
                  set -l raw_git_info (cat "$__git_tmpfile" 2>/dev/null)
                  # remove parentheses and add our custom formatting
                  if test -n "$raw_git_info"
                      set raw_git_info (string replace -r '^\s*\(' "" $raw_git_info)
                      set raw_git_info (string replace -r '\)\s*$' "" $raw_git_info)
                      set -g __git_info (set_color brblack)" on "(set_color normal)"$raw_git_info"
                  else
                      set -g __git_info ""
                  end
                  __git_cleanup
                  # force prompt redraw
                  commandline -f repaint 2>/dev/null
              end
          end

          function fish_prompt
              # get exit status before anything else
              set -l last_status $status
              set -l cwd (prompt_pwd)
              set -l prompt_char ' '

              # change prompt char color based on exit status
              set -l prompt_color green
              if test $last_status -ne 0
                  set prompt_color red
              end

              show execution time for long commands
              set -l duration_str ""
              if test -n "$CMD_DURATION"
                  and test $CMD_DURATION -gt 5000 # 5+ seconds
                  set duration_str (set_color brwhite)" ["(math $CMD_DURATION / 1000)"s]"(set_color normal)
              end

              # First line: directory, git info, and optional duration
              echo -s (set_color cyan) $cwd \
                  (set_color normal) $__git_info \
                  $duration_str (set_color normal)

              # Second line: prompt character with status-based coloring
              echo -n -s (set_color $prompt_color) $prompt_char " " (set_color normal)
          end

          # Clean up on exit
          function __git_cleanup_on_exit --on-event fish_exit
              # kill any running git jobs
              if test -n "$__git_pid"
                  and kill -0 $__git_pid 2>/dev/null
                  kill -TERM $__git_pid 2>/dev/null
                  # give it a moment to exit gracefully
                  sleep 0.1
                  # force kill if still running
                  if kill -0 $__git_pid 2>/dev/null
                      kill -KILL $__git_pid 2>/dev/null
                  end
              end
              __git_cleanup
          end

          # Initialize on startup
          __git_launch
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
