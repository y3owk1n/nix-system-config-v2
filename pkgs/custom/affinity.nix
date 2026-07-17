{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

let
  # BUMP: Latest version refer here -> https://github.com/Homebrew/homebrew-cask/blob/main/Casks/a/affinity.rb
  version = "3.2.3";
  build = "4646";
in
stdenvNoCC.mkDerivation {
  pname = "affinity";
  inherit version;

  src = fetchurl {
    url = "https://affinity-update.s3.amazonaws.com/mac2/retail/Affinity%20Affinity%20Store%20${build}.zip";
    hash = "sha256-m1s8Le/6yEEhNExd/1OsftTpv/HbHn6hBrAFTYxAU98=";
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
