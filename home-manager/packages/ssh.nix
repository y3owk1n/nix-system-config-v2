{ ... }:
{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    includes = [
      "~/.orbstack/ssh/config" # for orbstack
    ];
    extraConfig = ''
      Host github.com
        AddKeysToAgent yes
        UseKeychain yes
        IdentityFile ~/.ssh/id_ed25519
    '';
  };
}
