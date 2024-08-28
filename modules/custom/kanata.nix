let
  pkgs = import <nixpkgs> { };

  version = "1.7.0-prerelease-1";

  kanata_bin = pkgs.fetchurl {
    url = "https://github.com/jtroo/kanata/releases/download/v${version}/kanata_macos_arm64";
    sha256 = "08yxxdi8h105hqcg29vyq2hh9y8d59ippzcjas9j9w8153vl6xnb";
  };
in
pkgs.runCommand "kanata" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
  mkdir -p $out/bin
  cp ${kanata_bin} $out/bin/kanata
  chmod +x $out/bin/kanata
  # Optionally, you can create a symlink to make it accessible without specifying the path
  # ln -s $out/bin/kanata $out/bin/kanata
''
