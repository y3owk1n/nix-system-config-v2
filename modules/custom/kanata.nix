let
  pkgs = import <nixpkgs> { };

  version = "1.7.0-prerelease-2";

  kanata_bin = pkgs.fetchurl {
    url = "https://github.com/jtroo/kanata/releases/download/v${version}/kanata_macos_arm64";
    sha256 = "sha256-WcO3ilO8/9NQy2w7dkSRWiBmqMVSEtVCfA+I8tmZ+8o=";
  };
in
pkgs.runCommand "kanata" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
  mkdir -p $out/bin
  cp ${kanata_bin} $out/bin/kanata
  chmod +x $out/bin/kanata
  # Optionally, you can create a symlink to make it accessible without specifying the path
  # ln -s $out/bin/kanata $out/bin/kanata
''
