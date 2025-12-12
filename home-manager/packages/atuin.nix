_: {
  programs.atuin = {
    enable = true;
    daemon = {
      enable = true;
    };
    flags = [
      "--disable-up-arrow"
    ];
    settings = {
      auto_sync = true;
      enter_accept = true;
      sync_frequency = "1h";
      prefers_reduced_motion = true;
      workspaces = true;
      invert = true;
      sync.records = true;
    };
  };
}
