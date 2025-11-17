{ pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    # enableDefaultConfig = false; # Explicitly enable default config to suppress warning
    includes = (
      if pkgs.stdenv.isDarwin then
        [
          "~/.orbstack/ssh/config" # Orbstack in host macos
        ]
      else
        [ ]
    );
    extraConfig = ''
      Host github.com
      	AddKeysToAgent yes
      	${if pkgs.stdenv.isDarwin then "UseKeychain yes" else ""}
      	IdentityFile ~/.ssh/id_ed25519
    '';

    # matchBlocks = {
    #   # Global defaults (replacing the deprecated top-level addKeysToAgent)
    #   "*" = {
    #     forwardAgent = false;
    #     addKeysToAgent = "yes";
    #     compression = false;
    #     serverAliveInterval = 0;
    #     serverAliveCountMax = 3;
    #     hashKnownHosts = false;
    #     userKnownHostsFile = "~/.ssh/known_hosts";
    #     controlMaster = "no";
    #     controlPath = "~/.ssh/master-%r@%h:%p";
    #     controlPersist = "no";
    #   };
    #
    #   # GitHub-specific configuration
    #   "github.com" = {
    #     addKeysToAgent = "yes";
    #     identityFile = "~/.ssh/id_ed25519";
    #     extraOptions = {
    #       useKeychain = if pkgs.stdenv.isDarwin then "yes" else "no";
    #     };
    #   };
    # };
  };
}
