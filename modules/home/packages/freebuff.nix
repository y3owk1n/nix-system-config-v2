{ pkgs, ... }:

{
  home.packages = with pkgs.custom; [
    freebuff
  ];
}
