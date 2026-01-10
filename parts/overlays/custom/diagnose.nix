{
  lib,
  stdenv,
}:

# ============================================================================
# Diagnose
# ============================================================================
# Custom package that wraps the diagnose.sh script for running
# comprehensive performance diagnostics.

let
  version = "1.0.0";
in
stdenv.mkDerivation {
  pname = "diagnose";

  inherit version;

  src = lib.cleanSource ../../../scripts/diagnose.sh;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/diagnose
    chmod +x $out/bin/diagnose
  '';

}
