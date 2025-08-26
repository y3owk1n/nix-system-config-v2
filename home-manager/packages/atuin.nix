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
      enter_accept = true;
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
        # anything with password
        ".*password.*"
        ".*passwd.*"
        ".*secret.*"
        ".*token.*"
        ".*apikey.*"
        ".*api-key.*"
        ".*key=.*"
        ".*--password.*"
        ".*--secret.*"
        ".*--token.*"
        # ssh and keys
        ".*ssh .*@.*"
        ".*scp .*"
        ".*rsync .*@.*"
        ".*sshpass.*"
      ];
    };
  };
}
