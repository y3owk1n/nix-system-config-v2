{
  lib,
  stdenv,
  fetchurl,
  installShellFiles,
}:

stdenv.mkDerivation rec {
  pname = "skhd-zig";
  # BUMP: Latest release refer here -> https://github.com/jackielii/skhd.zig/releases/latest
  version = "0.1.9";

  src = fetchurl {
    url = "https://github.com/jackielii/skhd.zig/releases/download/v${version}/skhd-arm64-macos.tar.gz";
    sha256 = "sha256-CE5qZkDkm37iAtQwueiitmIQ/4RcdmZKJ4pUqDgam9Q=";
  };

  nativeBuildInputs = [ installShellFiles ];

  phases = [
    "unpackPhase"
    "installPhase"
  ];

  unpackPhase = ''
    tar -xvf $src
  '';

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/Applications
    mv skhd.app $out/Applications

    mkdir -p $out/bin
    ln -s $out/Applications/skhd.app/Contents/MacOS/skhd $out/bin/skhd
    ln -s $out/Applications/skhd.app/Contents/MacOS/skhd-grabber $out/bin/skhd-grabber
  '';

  meta = with lib; {
    description = "A hotkey daemon for macOS (Zig fork)";
    homepage = "https://github.com/jackielii/skhd.zig";
    license = licenses.mit;
    mainProgram = "skhd";
    platforms = [ "aarch64-darwin" ];
  };
}
