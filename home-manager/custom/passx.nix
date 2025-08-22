{
  pkgs,
  ...
}:

let
  passx = pkgs.stdenv.mkDerivation {
    name = "passx";
    version = "1.0";
    src = ../../scripts/passx.sh;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/passx
      chmod +x $out/bin/passx
    '';
  };
in
{
  home.packages = [
    passx
  ];
}
