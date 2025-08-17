{
  lib,
  useremail,
  githubuser,
  githubname,
  pkgs,
  config,
  gpgkeyid,
  ...
}:
let
  pubkeyPath = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
in
{
  # `programs.git` will generate the config file: ~/.config/git/config
  # to make git use this config file, `~/.gitconfig` should not exist!
  #
  #    https://git-scm.com/docs/git-config#Documentation/git-config.txt---global
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f ${config.home.homeDirectory}/.gitconfig
  '';

  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = githubname;
    userEmail = useremail;

    difftastic = {
      enable = true;
      background = "dark";
      color = "always";
      enableAsDifftool = true;
    };

    extraConfig = {
      advise.addEmptyPathSpec = false;
      advise.pushNonFastForward = false;
      advise.statusHints = false;
      branch.sort = "-committerdate";
      checkout.defaultRemote = "origin";
      color.branch = "auto";
      color.diff = "auto";
      color.status = "auto";
      color.ui = true;
      column.ui = "auto";
      commit.gpgSign = true;
      commit.verbose = true;
      core.autocrlf = "input";
      core.commitgraph = true;
      core.compression = 9;
      core.preloadindex = true;
      core.whitespace = "error";
      diff.context = 3;
      diff.innerHunkContext = 10;
      diff.mnemonicprefix = true;
      diff.renames = "copies";
      fetch.writeCommitGraph = true;
      gc.writeCommitGraph = true;
      github.user = githubuser;
      http.sslVerify = true;
      init.defaultBranch = "main";
      interactive.singlekey = true;
      log.abbrevCommit = true;
      merge.conflictstyle = "diff3";
      protocol.version = "2";
      pull.rebase = true;
      push.autoSetupRemote = true;
      push.default = "current";
      push.followTags = true;
      rebase.autoStash = true;
      rebase.missingCommitsCheck = "warn";
      rebase.stat = true;
      status.branch = true;
      status.showStash = true;
      status.showUntrackedFiles = "all";
    }
    // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
      # these should speed up vim nvim-tree and other things that watch git repos but
      # only works on mac. see https://github.com/nvim-tree/nvim-tree.lua/wiki/Troubleshooting#git-fsmonitor-daemon
      core.fsmonitor = true;
      core.untrackedcache = true;
      feature.manyFiles = true;
    };

    signing = {
      key = gpgkeyid;
      signByDefault = true;
    };
  };
}
