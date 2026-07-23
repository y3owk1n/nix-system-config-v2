{ pkgs, config, ... }:
{
  # dependencies for `uts`
  home.packages = with pkgs; [
    # Video & audio (used by pact video/audio)
    ffmpeg

    # PDF (used by pact pdf)
    ghostscript

    # Image optimization (used by pact image)
    pngquant
    optipng
    jpegoptim
    gifsicle
    libwebp # provides cwebp
    imagemagick

    # Archive algorithms (used by uts archive)
    zstd
    brotli
    xz

    # PDF to image conversion (used by uts convert pdf)
    poppler # provides pdftoppm
  ];

  programs.uts = {
    enable = true;
    package = pkgs.uts-source;
  };

  home.sessionVariables = {
    UTS_COLOR_PRIMARY = "#${config.lib.stylix.colors.base0E}";
    UTS_COLOR_TEXT = "#${config.lib.stylix.colors.base05}";
    UTS_COLOR_MUTED = "#${config.lib.stylix.colors.base04}";
    UTS_COLOR_SUBTLE = "#${config.lib.stylix.colors.base03}";
    UTS_COLOR_BORDER = "#${config.lib.stylix.colors.base02}";
    UTS_COLOR_ACCENT = "#${config.lib.stylix.colors.base0D}";
    UTS_COLOR_SUCCESS = "#${config.lib.stylix.colors.base0B}";
    UTS_COLOR_WARNING = "#${config.lib.stylix.colors.base0A}";
    UTS_COLOR_ERROR = "#${config.lib.stylix.colors.base08}";
  };
}
