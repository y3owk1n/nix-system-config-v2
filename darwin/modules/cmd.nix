{ pkgs, ... }:
let
  cmd = pkgs.stdenv.mkDerivation {
    pname = "cmd";
    version = "1.0";
    src = ../../scripts/run-project-cmd.sh;
    # skip all the build phases, just install
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      install -m755 "$src" $out/bin/cmd
    '';
  };
in
{
  environment.systemPackages = [
    cmd
  ];
}
