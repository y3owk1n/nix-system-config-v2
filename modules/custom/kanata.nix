let
  pkgs = import <nixpkgs> { };

  kanata_bin = pkgs.fetchurl {
    url = "https://github.com/jtroo/kanata/releases/download/v1.7.0-prerelease-1/kanata_macos_cmd_allowed_arm64";
    sha256 = "1c10i44slmw813gypcgjjwwn80xdsgv2kirzj27411qj96zv22am";
  };
in
pkgs.runCommand "kanata" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
  mkdir -p $out/bin
  cp ${kanata_bin} $out/bin/kanata
  chmod +x $out/bin/kanata
  # Optionally, you can create a symlink to make it accessible without specifying the path
  # ln -s $out/bin/kanata $out/bin/kanata
''
