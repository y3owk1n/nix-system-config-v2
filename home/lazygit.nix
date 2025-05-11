{ ... }:
{
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
}
