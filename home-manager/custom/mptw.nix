{
  pkgs,
  ...
}:

let
  mptw = pkgs.stdenv.mkDerivation {
    name = "mptw";
    version = "1.0";
    src = ../../scripts/move-pip-to-ws.sh;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/mptw
      chmod +x $out/bin/mptw
    '';
  };
in
{
  home.packages = [
    mptw
  ];
}
