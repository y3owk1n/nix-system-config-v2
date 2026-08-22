{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ast-grep
    custom.cmd
    custom.diagnose
    mkcert
    devbox
    rip2
  ];

  programs = {
    btop.enable = true;
    fd.enable = true;
    jq.enable = true;
    less.enable = true;
  };
}
