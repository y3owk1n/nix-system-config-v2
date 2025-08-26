{ ... }:
{
  programs.atuin = {
    enable = true;
    daemon = {
      enable = true;
    };
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
        "^c$"
        "^exit$"
        "^x$"
        "^fg$"
        "^vim$"
        "^vi$"
        "^nvim$"
        "^nvim$"
        "^gg$"
        "^s$"
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
