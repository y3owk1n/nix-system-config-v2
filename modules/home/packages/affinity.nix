{ pkgs, ... }: {
  home.packages = with pkgs; [
    custom.affinity
  ];
}
