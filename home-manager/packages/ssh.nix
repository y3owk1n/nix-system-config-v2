{ pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
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
  };
}
