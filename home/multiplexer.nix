{ pkgs, config, ... }:
{
  programs = {
    tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      escapeTime = 0;
      historyLimit = 50000;
      keyMode = "vi";
      mouse = true;
      sensibleOnTop = false;
      terminal = "xterm-ghostty";
      # terminal = "xterm-256color";
      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.vim-tmux-navigator.overrideAttrs (_: {
            src = pkgs.fetchFromGitHub {
              owner = "christoomey";
              repo = "vim-tmux-navigator";
              rev = "33afa80db65113561dc53fa732b7f5e53d5ecfd0";
              hash = "sha256-h3c5ki8N4kiNzbgjxHwLh625un6GqbLZv/4dPVW3vCI=";
            };
          });
        }
        {
          plugin = tmuxPlugins.catppuccin.overrideAttrs (_: {
            src = pkgs.fetchFromGitHub {
              owner = "catppuccin";
              repo = "tmux";
              rev = "14a546fb64dc1141e5d02bac2185d8c1fd530d6a";
              sha256 = "sha256-poG3QCow2j6h/G7BLEA8v3ZJXuk28iPmH1J4t7vT55k=";
            };
          });
          extraConfig = ''
            set -g @catppuccin_flavor "macchiato"
            set -g @catppuccin_window_status_style "rounded"
            set -g @catppuccin_status_background "#{@thm_bg}"
            set -g @catppuccin_window_number_position "right"
            set -g @catppuccin_window_text "#W"
            set -g @catppuccin_window_number "#I"
            set -g @catppuccin_window_current_text "#W"
            set -g @catppuccin_window_current_number "#I"
          '';
        }
        {
          plugin = tmuxPlugins.resurrect.overrideAttrs (_: {
            src = pkgs.fetchFromGitHub {
              owner = "tmux-plugins";
              repo = "tmux-resurrect";
              rev = "cff343cf9e81983d3da0c8562b01616f12e8d548";
              sha256 = "sha256-FcSjYyWjXM1B+WmiK2bqUNJYtH7sJBUsY2IjSur5TjY=";
            };
            # NOTE: temporary workaround that causes the rebuild to fail
            preFixup = ''
              # Remove dangling symlinks that point to missing test targets.
              rm -f $out/share/tmux-plugins/resurrect/run_tests
              rm -rf $out/share/tmux-plugins/resurrect/tests
            '';
          });
          extraConfig = ''
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-strategy-nvim 'session'
          '';
        }
        {
          plugin = tmuxPlugins.continuum.overrideAttrs (_: {
            src = pkgs.fetchFromGitHub {
              owner = "tmux-plugins";
              repo = "tmux-continuum";
              rev = "0698e8f4b17d6454c71bf5212895ec055c578da0";
              sha256 = "sha256-W71QyLwC/MXz3bcLR2aJeWcoXFI/A3itjpcWKAdVFJY=";
            };
          });
          extraConfig = ''
            set -g @continuum-restore 'on'
          '';
        }
      ];
      extraConfig = ''
        bind -r j resize-pane -D 5
        bind -r k resize-pane -U 5
        bind -r l resize-pane -R 5
        bind -r h resize-pane -L 5
        bind -r m resize-pane -Z

        bind-key b run-shell "tms"

        bind-key C-n switch-client -T dotmd
        bind-key -T dotmd t run-shell "tmux popup -E -w 90% -h 80% -T 'Dotmd Todo' 'sh -c \"cd ~/Library/Mobile\\ Documents/com~apple~CloudDocs/Cloud\\ Notes && nvim +\\\"DotMdCreateTodoToday split=none\\\"\"'"
        bind-key -T dotmd n run-shell "tmux popup -E -w 90% -h 80% -T 'Dotmd Note' 'sh -c \"cd ~/Library/Mobile\\ Documents/com~apple~CloudDocs/Cloud\\ Notes && nvim +\\\"DotMdCreateNote split=none\\\"\"'"
        bind-key -T dotmd i run-shell "tmux popup -E -w 90% -h 80% -T 'Dotmd Inbox' 'sh -c \"cd ~/Library/Mobile\\ Documents/com~apple~CloudDocs/Cloud\\ Notes && nvim +\\\"DotMdInbox split=none\\\"\"'"
        bind-key -T dotmd p run-shell "tmux popup -E -w 90% -h 80% -T 'Dotmd Pick' 'sh -c \"cd ~/Library/Mobile\\ Documents/com~apple~CloudDocs/Cloud\\ Notes && nvim +\\\"DotMdPick\\\"\"'"
        bind-key -T dotmd r run-shell "tmux popup -E -w 90% -h 80% -T 'Dotmd Root' 'sh -c \"cd ~/Library/Mobile\\ Documents/com~apple~CloudDocs/Cloud\\ Notes && nvim\"'"
        bind-key -T dotmd Escape switch-client -T root

        bind-key -T copy-mode-vi 'v' send -X begin-selection # start selecting text with "v"
        bind-key -T copy-mode-vi 'y' send -X copy-selection # copy text with "y"

        set -g allow-passthrough on

        set-option -g default-shell "${pkgs.fish}/bin/fish"
        set-option -g default-command "${pkgs.fish}/bin/fish"
        set-option -ga terminal-overrides ',*:Tc'
        set -g focus-events on
        set -g repeat-time 1000
        set -g detach-on-destroy off
        set -g renumber-windows on
        set -g set-clipboard on
        set -g display-time 4000

        set -g status-format[1] '#[align=centre]'
        set -g status 2
        set -g status-interval 5
        set -g status-position top
        set -g status-right-length 100
        set -g status-left-length 100
        set -g status-left "#{E:@catppuccin_status_session}"
        set -gF  status-right "#{@catppuccin_status_directory}"
        set -agF status-right "#{@catppuccin_status_user}"
        set -agF status-right "#{@catppuccin_status_host}"
      '';
    };
  };
}
