{
  lib,
  stdenv,
}:

# ============================================================================
# Move to space
# ============================================================================
# Best effort to move an app to a specific space with actual macos spaces

let
  version = "1.0.0";
in
stdenv.mkDerivation {
  pname = "move-to-space";

  inherit version;

  src = lib.cleanSource ../../../scripts/move-app-to-space;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/move-to-space
    chmod +x $out/bin/move-to-space
  '';

}
