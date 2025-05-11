{
  lib,
  useremail,
  githubuser,
  pkgs,
  ...
}:
{
  # `programs.git` will generate the config file: ~/.config/git/config
  # to make git use this config file, `~/.gitconfig` should not exist!
  #
  #    https://git-scm.com/docs/git-config#Documentation/git-config.txt---global
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f ~/.gitconfig
  '';

  home.file.".ssh/allowed_signers".text = "* ${builtins.readFile ~/.ssh/id_ed25519.pub}";

  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = githubuser;
    userEmail = useremail;

    difftastic = {
      enable = true;
      background = "dark";
      color = "always";
      enableAsDifftool = true;
    };

    extraConfig =
      {
        color.ui = true;
        commit.verbose = true;
        commit.gpgSign = true;
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        github.user = githubuser;
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
        rebase.autoStash = true;
        rebase.missingCommitsCheck = "warn";
        merge.conflictstyle = "diff3";
        log.abbrevCommit = true;
        http.sslVerify = true;
        diff.context = 3;
        diff.renames = "copies";
        diff.innerHunkContext = 10;
        protocol.version = "2";
        core.commitGraph = true;
        core.compression = 9;
        core.whitespace = "error";
        core.preloadindex = true;
        gc.writeCommitGraph = true;
        advise.addEmptyPathSpec = false;
        advise.pushNonFastForward = false;
        advise.statusHints = false;
        status.branch = true;
        status.showStash = true;
        status.showUntrackedFiles = "all";
        interactive.singlekey = true;
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
        # these should speed up vim nvim-tree and other things that watch git repos but
        # only works on mac. see https://github.com/nvim-tree/nvim-tree.lua/wiki/Troubleshooting#git-fsmonitor-daemon
        core.fsmonitor = true;
        core.untrackedcache = true;
        feature.manyFiles = true;
      };

    signing = {
      key = "~/.ssh/id_ed25519.pub";
      format = "ssh";
      signByDefault = true;
    };
  };
}
