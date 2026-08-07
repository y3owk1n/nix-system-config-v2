_: {
  programs.lazygit = {
    enable = true;
    settings = {
      disableStartupPopups = true;
      os.editPreset = "nvim-remote";
      gui = {
        nerdFontsVersion = "3";
        showNumstatInFilesView = true;
        showRandomTip = false;
      };
      git = {
        diffRenderers = [
          {
            command = "difft --color=always";
            type = "extDiff";
          }
        ];
      };
    };
  };
}
