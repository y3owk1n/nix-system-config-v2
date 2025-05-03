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

  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = githubuser;
    userEmail = useremail;

    difftastic = {
      enable = true;
      background = "dark";
      color = "always";
    };

    extraConfig =
      {
        github.user = githubuser;
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
        color.ui = true;
        merge.conflictstyle = "diff3";
        http.sslVerify = true;
        commit.verbose = true;
        diff.algorithm = "patience";
        protocol.version = "2";
        core.commitGraph = true;
        gc.writeCommitGraph = true;
      }
      // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
        # these should speed up vim nvim-tree and other things that watch git repos but
        # only works on mac. see https://github.com/nvim-tree/nvim-tree.lua/wiki/Troubleshooting#git-fsmonitor-daemon
        core.fsmonitor = true;
        core.untrackedcache = true;
        feature.manyFiles = true;
      };

    # signing = {
    #   key = "xxx";
    #   signByDefault = true;
    # };
  };

  # Simple terminal UI for git commands
  programs.lazygit = {
    enable = true;
    settings = {
      os.editPreset = "nvim-remote";
      gui = {
        nerdFontsVersion = "3";
        theme = {
          activeBorderColor = [
            "#f5a97f"
            "bold"
          ];
          inactiveBorderColor = [ "#8aadf4" ];
          optionsTextColor = [ "#8aadf4" ];
          selectedLineBgColor = [ "#494d64" ];
          cherryPickedCommitBgColor = [ "#f0c6c6" ];
          cherryPickedCommitFgColor = [ "#8aadf4" ];
          unstagedChangesColor = [ "#ed8796" ];
          defaultFgColor = [ "#cad3f5" ];
          searchingActiveBorderColor = [
            "#f5a97f"
            "bold"
          ];
        };

      };
    };
  };

  # Jujutsu
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        email = useremail;
        name = githubuser;
      };
    };
  };
}
