{ pkgs, ... }: {
  home.packages = with pkgs; [
    custom.mole
  ];
}
