{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

let
  # BUMP: Latest version refer here -> https://github.com/Homebrew/homebrew-cask/blob/main/Casks/a/affinity.rb
  version = "3.3.0";
  build = "4850";
in
stdenvNoCC.mkDerivation {
  pname = "affinity";
  inherit version;

  src = fetchurl {
    url = "https://affinity-update.s3.amazonaws.com/mac2/retail/Affinity%20Affinity%20Store%20${build}.zip";
    hash = "sha256-MX9c9kpTZDGYmFdrRki2qW3J7Dn1ADmuv5kBt+06XZY=";
  };

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R "$PWD" "$out/Applications/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Professional image editing and design software (Affinity Studio)";
    homepage = "https://affinity.serif.com";
    license = licenses.unfree;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = platforms.darwin;
  };
}
