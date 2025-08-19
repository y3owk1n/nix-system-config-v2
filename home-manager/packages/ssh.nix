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
  };
}
