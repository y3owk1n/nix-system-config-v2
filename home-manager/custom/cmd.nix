{
  pkgs,
  ...
}:

let
  cmd = pkgs.stdenv.mkDerivation {
    name = "cmd";
    version = "1.0";
    src = ../../scripts/run-project-cmd.sh;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/cmd
      chmod +x $out/bin/cmd
    '';
  };
in
{
  home.packages = [
    cmd
  ];
}
