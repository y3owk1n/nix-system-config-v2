{
  config,
  ...
}:
{
  xdg.configFile.nvim = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/nvim";
    recursive = true;
  };

  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        indent_size = 4;
        indent_style = "tab";
        insert_final_newline = true;
        trim_trailing_whitespace = true;
        max_line_width = 120;
      };
    };
  };
}
