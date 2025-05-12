{ ... }:
{
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
        paging = {
          externalDiffCommand = "difft --color=always";
        };
      };
    };
  };
}
