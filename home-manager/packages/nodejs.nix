{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_22
    # corepack_latest
    # corepack_22 # pin to 22 instead, latest is fetching rc versions
  ];
}
