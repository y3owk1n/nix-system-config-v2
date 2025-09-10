{ lib, pkgs, ... }:
let
  fish = "${pkgs.fish}/bin/fish";
in
{
  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    baseIndex = 1;
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 50000;
    keyMode = "vi";
    mouse = false;
    disableConfirmationPrompt = true;
    shell = fish;
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
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",xterm-ghostty:Tc"
      set -ga terminal-features ",*:usstyle,*:RGB,*:strikethrough"

      bind -r j resize-pane -D 5
      bind -r k resize-pane -U 5
      bind -r l resize-pane -R 5
      bind -r h resize-pane -L 5
      bind -r m resize-pane -Z

      bind -N "last-session (via sesh) " L run-shell "sesh last" # overwrite last-session with sesh last

      bind C-g display-popup -T "Lazygit" -w 90% -h 80% -d "#{pane_current_path}" -E "lazygit"
      bind C-t display-popup -T "Terminal" -w 90% -h 80% -d "#{pane_current_path}" -E $SHELL

      bind-key C-n switch-client -T dotmd
      bind-key -T dotmd t display-popup -w 90% -h 80% -T "Dotmd Todo" -d ~/Library/Mobile\ Documents/com~apple~CloudDocs/Cloud\ Notes -E "nvim +\'DotMdCreateTodoToday split=none\'"
      bind-key -T dotmd n display-popup -w 90% -h 80% -T "Dotmd Note" -d ~/Library/Mobile\ Documents/com~apple~CloudDocs/Cloud\ Notes -E "nvim +\'DotMdCreateNote split=none\'"
      bind-key -T dotmd i display-popup -w 90% -h 80% -T "Dotmd Inbox" -d ~/Library/Mobile\ Documents/com~apple~CloudDocs/Cloud\ Notes -E "nvim +\'DotMdInbox split=none\'"
      bind-key -T dotmd p display-popup -w 90% -h 80% -T "Dotmd Pick" -d ~/Library/Mobile\ Documents/com~apple~CloudDocs/Cloud\ Notes -E "nvim +DotMdPick"
      bind-key -T dotmd r display-popup -w 90% -h 80% -T "Dotmd Root" -d ~/Library/Mobile\ Documents/com~apple~CloudDocs/Cloud\ Notes -E "nvim"
      bind-key -T dotmd Escape switch-client -T root

      bind-key -T copy-mode-vi 'v' send -X begin-selection # start selecting text with "v"
      bind-key -T copy-mode-vi 'y' send -X copy-selection # copy text with "y"

      set -g allow-passthrough on

      set -g repeat-time 1000
      set -g detach-on-destroy off
      set -g renumber-windows on
      set -g set-clipboard on
      set -g display-time 4000

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        	set-option -g default-command "${pkgs.reattach-to-user-namespace}/bin/reattach-to-user-namespace -l ${fish}"
      ''}

      set -g popup-border-lines rounded

      set -g status-interval 5
      set -g status-position top
      set -g status-justify absolute-centre
      set -g status-left "#S #{?client_prefix,,}"
      set -g status-right "#H"
      set -g status-left-length 30
      set -g status-right-length 30
    '';
  };
}
