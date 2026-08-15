{ pkgs, ... }:
{
  services.ssh-agent.enable = pkgs.stdenv.hostPlatform.isLinux;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # Explicitly enable default config to suppress warning
    includes =
      if pkgs.stdenv.hostPlatform.isDarwin then
        [
          "~/.orbstack/ssh/config" # Orbstack in host macos
        ]
      else
        [ ];

    settings = {
      # Global defaults
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "yes";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%h:%p";
        ControlPersist = "no";
      };

      # GitHub-specific configuration
      "github.com" = {
        AddKeysToAgent = "yes";
        IdentityFile = "~/.ssh/id_ed25519";
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        UseKeychain = "yes";
      };
    };
  };
}
