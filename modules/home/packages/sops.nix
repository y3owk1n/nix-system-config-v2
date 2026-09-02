{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.sops
    pkgs.age
  ];

  # Bootstrap on a new machine: put the age identity at
  # ~/.config/sops/age/keys.txt, then rebuild.
  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = ../../../secrets/secrets.yaml;

    secrets."ssh/id_ed25519" = {
      path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      mode = "0600";
    };
  };
}
