{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

let
  version = "3.2.2";
  build = "4557";
in
stdenvNoCC.mkDerivation {
  pname = "affinity";
  inherit version;

  src = fetchurl {
    url = "https://affinity-update.s3.amazonaws.com/mac2/retail/Affinity%20Affinity%20Store%20${build}.zip";
    hash = "sha256-qTpfpNfjqHKN4ihsKpPKqFQY3jAAN5Tj1JnWS44Rs2Y=";
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
