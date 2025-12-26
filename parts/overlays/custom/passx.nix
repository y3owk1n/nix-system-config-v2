{
  lib,
  stdenv,
}:

# ============================================================================
# Passx
# ============================================================================
# Custom package that wraps pass commands with project based management.

let
  version = "1.0.0";
in
stdenv.mkDerivation {
  pname = "passx";

  inherit version;

  src = lib.cleanSource ../../../scripts/passx.sh;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/passx
    chmod +x $out/bin/passx
  '';

}
