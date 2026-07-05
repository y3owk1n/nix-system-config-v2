{
  stdenv,
}:

# ============================================================================
# UTS
# ============================================================================
# All-in-one utility toolkit with category-based subcommands.

let
  version = "1.0.0";
in
stdenv.mkDerivation {
  pname = "uts";

  inherit version;

  src = ../../scripts/uts.sh;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/uts
    chmod +x $out/bin/uts
  '';
}
