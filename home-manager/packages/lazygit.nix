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
        pagers = [
          {
            externalDiffCommand = "difft --color=always";
          }
        ];
      };
    };
  };
}
