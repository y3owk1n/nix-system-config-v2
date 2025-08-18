{ pkgs, ... }:
let
  passx = pkgs.stdenv.mkDerivation {
    pname = "passx";
    version = "1.0";
    src = ../../scripts/passx.sh;
    # skip all the build phases, just install
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      install -m755 "$src" $out/bin/passx
    '';
  };
in
{
  environment.systemPackages = [
    passx
  ];
}
