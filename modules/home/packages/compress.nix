{ pkgs, ... }: {
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
}
