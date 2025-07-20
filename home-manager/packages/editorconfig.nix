{ ... }:
{
  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        indent_style = "tab";
        tab_width = 4;
        indent_size = 4;
        end_of_line = "lf";
        insert_final_newline = true;
        trim_trailing_whitespace = true;
        max_line_width = 120;
      };
      "*.{yaml,yml}" = {
        indent_style = "space";
        tab_width = 2;
        indent_size = 2;
      };
      "Justfile" = {
        indent_style = "space";
        tab_width = 2;
        indent_size = 2;
      };
    };
  };
}
