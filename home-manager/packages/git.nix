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

    settings = {
      user.email = useremail;
      user.name = githubname;
      advise = {
        addEmptyPathSpec = false;
        pushNonFastForward = false;
        statusHints = false;
      };
      branch.sort = "-committerdate";
      checkout.defaultRemote = "origin";
      color = {
        branch = "auto";
        diff = "auto";
        status = "auto";
        ui = true;
      };
      column.ui = "auto";
      commit.gpgSign = true;
      commit.verbose = true;
      core = {
        autocrlf = "input";
        commitgraph = true;
        compression = 9;
        preloadindex = true;
        whitespace = "error";
      };
      diff = {
        context = 3;
        innerHunkContext = 10;
        mnemonicprefix = true;
        renames = "copies";
      };
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
      push = {
        autoSetupRemote = true;
        default = "current";
        followTags = true;
      };
      rebase = {
        autoStash = true;
        missingCommitsCheck = "warn";
        stat = true;
      };
      status = {
        branch = true;
        showStash = true;
        showUntrackedFiles = "all";
      };
      url."git@github.com:".insteadOf = "https://github.com/"; # Rewrite any HTTPS GitHub URL into SSH automatically
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

  programs.difftastic = {
    enable = true;
    git = {
      enable = true;
      diffToolMode = true;
    };
    options = {
      background = "dark";
      color = "always";
    };
  };
}
