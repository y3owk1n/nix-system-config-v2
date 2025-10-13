{
  fetchzip,
  stdenv,
}:

let
  appName = "Hammerspoon.app";
  version = "1.0.0";
in
stdenv.mkDerivation {
  pname = "hammerspoon";

  inherit version;

  src = fetchzip {
    url = "https://github.com/Hammerspoon/hammerspoon/releases/download/${version}/Hammerspoon-${version}.zip";
    sha256 = "sha256-CuTFI9qXHplhWLeHS7bgZJolULbg9jQRyT6MTKzkQqs=";
    stripRoot = false;
  };

  installPhase = ''
    mkdir -p $out/Applications
    cp -R ${appName} $out/Applications
  '';

}
