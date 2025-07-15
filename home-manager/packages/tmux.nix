{ lib, pkgs, ... }:
let
  fish = "${pkgs.fish}/bin/fish";
in
{
  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    baseIndex = 1;
    escapeTime = 10;
    focusEvents = true;
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;
    disableConfirmationPrompt = true;
    shell = fish;
    terminal = "screen-256color";
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.vim-tmux-navigator.overrideAttrs (_: {
          src = pkgs.fetchFromGitHub {
            owner = "christoomey";
            repo = "vim-tmux-navigator";
            rev = "c45243dc1f32ac6bcf6068e5300f3b2b237e576a";
            hash = "sha256-IEPnr/GdsAnHzdTjFnXCuMyoNLm3/Jz4cBAM0AJBrj8=";
          };
        });
      }
    ];
    extraConfig = ''
      bind -r j resize-pane -D 5
      bind -r k resize-pane -U 5
      bind -r l resize-pane -R 5
      bind -r h resize-pane -L 5
      bind -r m resize-pane -Z

      bind -N "last-session (via sesh) " L run-shell "sesh last" # overwrite last-session with sesh last

      bind-key C-n switch-client -T dotmd
      bind-key -T dotmd t run-shell "tmux popup -E -w 90% -h 80% -T 'Dotmd Todo' 'sh -c \"cd /Users/kylewong/Library/Mobile\\ Documents/com~apple~CloudDocs/Cloud\\ Notes && nvim +\\\"DotMdCreateTodoToday split=none\\\"\"'"
      bind-key -T dotmd n run-shell "tmux popup -E -w 90% -h 80% -T 'Dotmd Note' 'sh -c \"cd /Users/kylewong/Library/Mobile\\ Documents/com~apple~CloudDocs/Cloud\\ Notes && nvim +\\\"DotMdCreateNote split=none\\\"\"'"
      bind-key -T dotmd i run-shell "tmux popup -E -w 90% -h 80% -T 'Dotmd Inbox' 'sh -c \"cd /Users/kylewong/Library/Mobile\\ Documents/com~apple~CloudDocs/Cloud\\ Notes && nvim +\\\"DotMdInbox split=none\\\"\"'"
      bind-key -T dotmd p run-shell "tmux popup -E -w 90% -h 80% -T 'Dotmd Pick' 'sh -c \"cd /Users/kylewong/Library/Mobile\\ Documents/com~apple~CloudDocs/Cloud\\ Notes && nvim +\\\"DotMdPick\\\"\"'"
      bind-key -T dotmd r run-shell "tmux popup -E -w 90% -h 80% -T 'Dotmd Root' 'sh -c \"cd /Users/kylewong/Library/Mobile\\ Documents/com~apple~CloudDocs/Cloud\\ Notes && nvim\"'"
      bind-key -T dotmd Escape switch-client -T root

      bind-key -T copy-mode-vi 'v' send -X begin-selection # start selecting text with "v"
      bind-key -T copy-mode-vi 'y' send -X copy-selection # copy text with "y"

      set -g allow-passthrough on

      set-option -ga terminal-overrides ',*:Tc'
      set -g repeat-time 1000
      set -g detach-on-destroy off
      set -g renumber-windows on
      set -g set-clipboard on
      set -g display-time 4000

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        	set-option -g default-command "${pkgs.reattach-to-user-namespace}/bin/reattach-to-user-namespace -l ${fish}"
      ''}

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
  catppuccin = {
    tmux = {
      enable = true;
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
    };
  };
}
