{
  pkgs,
  ...
}:

let
  asr = pkgs.stdenv.mkDerivation {
    name = "asr";
    version = "1.0";
    src = ../../scripts/atuin-run-script.sh;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/asr
      chmod +x $out/bin/asr
    '';
  };
in
{
  home.packages = [
    asr
  ];
}
