{ pkgs, config, ... }:
{
  xdg.configFile.zellij = {
    enable = false;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/zellij";
    recursive = true;
  };

  programs = {
    tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      escapeTime = 0;
      historyLimit = 50000;
      keyMode = "vi";
      mouse = true;
      prefix = "C-t";
      sensibleOnTop = true;
      shell = "${pkgs.fish}/bin/fish";
      terminal = "screen-256color";
      plugins = with pkgs; [
        tmuxPlugins.sensible
        tmuxPlugins.vim-tmux-navigator
        {
          plugin = tmuxPlugins.catppuccin.overrideAttrs (_: {
            src = pkgs.fetchFromGitHub {
              owner = "catppuccin";
              repo = "tmux";
              rev = "c8a2d1ae9649aa904960bef1516ea2ff9a3e6ad0";
              sha256 = "sha256-MfdheWYVvfF++D5bftwAQVe/MY5eWD+igMaM+ELSyQA=";
            };
          });
          extraConfig = ''
            set -g @catppuccin_flavor "macchiato"
            set -g @catppuccin_window_status_style "rounded"
            set -g @catppuccin_window_number_position "right"
            set -g @catppuccin_window_text "#W"
            set -g @catppuccin_window_number "#I"
            set -g @catppuccin_window_current_text "#W"
            set -g @catppuccin_window_current_number "#I"
            set -g @catppuccin_status_modules_right "directory meetings date_time"
            set -g @catppuccin_status_modules_left "session"
            set -g @catppuccin_status_left_separator  " "
            set -g @catppuccin_status_right_separator " "
            set -g @catppuccin_status_right_separator_inverse "no"
            set -g @catppuccin_status_fill "icon"
            set -g @catppuccin_status_connect_separator "no"
            set -g @catppuccin_directory_text "#{pane_current_path}"
            set -g @catppuccin_date_time_text "%H:%M"
          '';
        }
        {
          plugin = tmuxPlugins.resurrect;
          extraConfig = ''
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-strategy-nvim 'session'
          '';
        }
        {
          plugin = tmuxPlugins.continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
          '';
        }
        {
          plugin = tmuxPlugins.fzf-tmux-url;
          extraConfig = ''
            set -g @fzf-url-fzf-options '-p 60%,30% --prompt="   " --border-label=" Open URL "'
            set -g @fzf-url-history-limit '2000'
          '';
        }
      ];
      extraConfig = ''
        unbind o

        unbind %
        bind \\ split-window -h -c "#{pane_current_path}"

        unbind '"'
        bind - split-window -v -c "#{pane_current_path}"

        unbind r
        bind R source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded..."

        bind -r j resize-pane -D 5
        bind -r k resize-pane -U 5
        bind -r l resize-pane -R 5
        bind -r h resize-pane -L 5
        bind -r m resize-pane -Z

        bind-key -T copy-mode-vi 'v' send -X begin-selection # start selecting text with "v"
        bind-key -T copy-mode-vi 'y' send -X copy-selection # copy text with "y"

        set-option -g default-command "${pkgs.fish}/bin/fish"
        set -ag terminal-overrides ",xterm-256color:RGB"
        set -g focus-events on
        set -g repeat-time 1000
        set -g detach-on-destroy off
        set -g renumber-windows on
        set -g set-clipboard on
        set -g status-position top
        set -g display-time 4000
        set -g status-interval 5

        set -g status 2

        set -g status-format[1] '#[align=centre]'
      '';
    };
  };
}
