{ ... }:
{
  programs.sesh = {
    enable = true;
    enableAlias = true;
    enableTmuxIntegration = true;
    tmuxKey = "b";
    settings = {
      default_session = {
        startup_command = "ls";
        preview_command = "tree -L 1 -C --dirsfirst -a {}";
      };

      session = [
        {
          name = "home (~)";
          path = "~";
        }
        {
          name = "start kanata";
          path = "~/nix-system-config-v2/";
          startup_command = "just kanata";
        }
        {
          name = "downloads";
          path = "~/Downloads";
        }
        {
          name = "nix config";
          path = "~/nix-system-config-v2";
        }
        {
          name = "neovim config";
          path = "~/nix-system-config-v2/config/nvim";
        }
        {
          name = "sesh config";
          path = "~/nix-system-config-v2/config/sesh";
          startup_command = "nvim sesh.toml";
          preview_command = "bat --color=always ~/nix-system-config-v2/config/sesh/sesh.toml";
        }
        {
          name = "ghostty config";
          path = "~/nix-system-config-v2/config/ghostty";
          startup_command = "nvim config";
          preview_command = "bat --color=always ~/nix-system-config-v2/config/ghostty/config";
        }
        {
          name = "tmux config";
          path = "~/nix-system-config-v2/home";
          startup_command = "nvim multiplexer.nix";
          preview_command = "bat --color=always ~/nix-system-config-v2/home/multiplexer.nix";
        }
        {
          name = "aerospace config";
          path = "~/nix-system-config-v2/modules/custom";
          startup_command = "nvim aerospace.nix";
          preview_command = "bat --color=always ~/nix-system-config-v2/modules/custom/aerospace.nix";
        }
        {
          name = "btop";
          path = "~";
          startup_command = "btop";
        }
      ];
    };
  };
}
