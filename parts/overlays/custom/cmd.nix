{
  lib,
  stdenv,
}:

# ============================================================================
# Cmd to fzf picker
# ============================================================================
# Custom package that wraps fzf picker to project based commands.
# E.g. npm, just, etc.

let
  version = "1.0.0";
in
stdenv.mkDerivation {
  pname = "cmd";

  inherit version;

  src = lib.cleanSource ../../../scripts/run-project-cmd.sh;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/cmd
    chmod +x $out/bin/cmd
  '';

}
