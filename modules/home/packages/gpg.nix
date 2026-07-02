{ pkgs, ... }:

{
  programs.gpg = {
    enable = true;
    # Adds `gpg` to PATH and sets up basic config
    # You can also provide `settings` if you want default options
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800; # seconds (30min)
    maxCacheTtl = 7200; # 2h
    enableSshSupport = if pkgs.stdenv.isDarwin then true else false; # can also use GPG agent as SSH agent
    pinentry.package = if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
  };
}
