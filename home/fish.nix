{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting\n
    '';
    shellInit = ''
      __load-em
      __autols_hook
      starship_transient_prompt_func
      fnm env --use-on-cd --version-file-strategy=recursive --resolve-engines --shell fish | source
      setup_homebrew_completion
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
        name = "pisces"; # auto pair brackets
        src = pkgs.fishPlugins.pisces.src;
      }
      {
        name = "sponge"; # clean history from typo
        src = pkgs.fishPlugins.sponge.src;
      }
      {
        name = "plugin-git"; # amazing git aliases
        src = pkgs.fishPlugins.plugin-git.src;
      }
      {
        name = "fish-x";
        src = pkgs.fetchFromGitHub {
          owner = "y3owk1n";
          repo = "fish-x";
          rev = "v1.3.0";
          sha256 = "sha256-WaLdl1h3XpS8k7lOwj/MMlQTvaaUBT2CWAYYPBcMESc=";
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
      setup_homebrew_completion = {
        description = "Setup homebrew completion";
        body = ''
          if test -d (brew --prefix)"/share/fish/completions"
          	set -p fish_complete_path (brew --prefix)/share/fish/completions
          end

          if test -d (brew --prefix)"/share/fish/vendor_completions.d"
          	set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
          end
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
