let
  pkgs = import <nixpkgs> { };

  version = "1.7.0";

  kanata_bin = pkgs.fetchurl {
    url = "https://github.com/jtroo/kanata/releases/download/v${version}/kanata_macos_arm64";
    sha256 = "sha256-g62A+6+Mew7A4XBSoCygswV8u+r4oCOmFUHxUUqTa0M=";
  };
in
pkgs.runCommand "kanata" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
  mkdir -p $out/bin
  cp ${kanata_bin} $out/bin/kanata
  chmod +x $out/bin/kanata
  # Optionally, you can create a symlink to make it accessible without specifying the path
  # ln -s $out/bin/kanata $out/bin/kanata
''
