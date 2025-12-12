_:

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
    enableSshSupport = true; # can also use GPG agent as SSH agent
  };
}
