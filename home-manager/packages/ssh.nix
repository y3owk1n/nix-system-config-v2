{ pkgs, ... }:
{
  services.ssh-agent.enable = pkgs.stdenv.isLinux;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # Explicitly enable default config to suppress warning
    includes =
      if pkgs.stdenv.isDarwin then
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
        UseKeychain = if pkgs.stdenv.isDarwin then "yes" else "no";
      };
    };
  };
}
