{ ... }:
{
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
      history_filter = [
        # some git commands that target directories
        "^git branch -D"
        "^git checkout -b"
        "^git clone"
        "^git add"
        "^git commit -m"
        "^git remote set-url"
        # some general commands
        "^rip"
        "^rm"
        "^chmod"
        "^ls"
        "^cd"
        "^pwd$"
        "^clear$"
        "^exit$"
        "^fg$"
        "^vim$"
        "^vi$"
        "^nvim$"
        "^nvim$"
        # aliases
        "^gg$"
        "^s$"
        "^tx$"
        "^x$"
        "^c$"
        # ssh and keys
        ".*ssh .*@.*"
        ".*scp .*"
        ".*rsync .*@.*"
        ".*sshpass.*"
      ];
      sync.records = true;
    };
  };
}
