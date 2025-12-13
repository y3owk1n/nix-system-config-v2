{
  lib,
  stdenv,
}:

# ============================================================================
# Atuin Run Script (ASR)
# ============================================================================
# Custom package that wraps the atuin-run-script.sh script for running
# Atuin commands from the command line.

let
  version = "1.0.0";
in
stdenv.mkDerivation {
  pname = "asr";

  inherit version;

  src = lib.cleanSource ../../scripts/atuin-run-script.sh;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/asr
    chmod +x $out/bin/asr
  '';

}
