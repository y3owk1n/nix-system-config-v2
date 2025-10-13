{
  fetchurl,
  stdenv,
}:
let
  appName = "ImageOptim.app";
  version = "1.9.3";
in
stdenv.mkDerivation {
  pname = "imageoptim-for-mac";
  inherit version;

  src = fetchurl {
    url = "https://imageoptim.com/ImageOptim${version}.tar.xz";
    sha256 = "sha256-1ORTu7VbZJHVGaMODm3lvrfOGpKej4NXZ7Y472/9Nx0=";
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/Applications
    cp -R ${appName} $out/Applications
  '';
}
