{
  config,
  pkgs,
  lib,
  ...
}:

let
  system = pkgs.system;

  version = "1.10.6";

  inherit (lib) mkIf;
  nvsInfo = {
    "x86_64-linux" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-linux-amd64";
      # use `nix hash convert --hash-algo sha256 <checksum>`
      # even better "awk '{print $1}' <checksum> | xargs nix hash convert --hash-algo sha256"
      sha256 = "sha256-pmhsRaXmaTvk4Ecxc0StCaQHWS6oAx1z+PEA/qMUJpo=";
    };
    "aarch64-linux" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-linux-arm64";
      sha256 = "sha256-P3Kd84QJMx6BstMbpYIyUj6W6MZl/QOpI1BSVwz5PEE=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-darwin-amd64";
      sha256 = "sha256-MKV7teliGfCKUGyUt+78NTa97+2lVZ5g8u/1EhG/cqY=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-darwin-arm64";
      sha256 = "sha256-LzUVm0kyaG5N8HKlBUF1MxjH/o99zRIeM4ZBFGtvw4Y=";
    };
  };

  nvsMeta = nvsInfo.${system} or (throw "Unsupported system: ${system}");

  nvs = pkgs.stdenv.mkDerivation {
    name = "nvs";
    src = pkgs.fetchurl {
      url = nvsMeta.url;
      sha256 = nvsMeta.sha256;
    };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/nvs
      chmod +x $out/bin/nvs

      mkdir -p $out/share/fish/vendor_completions.d
      HOME=$(mktemp -d) $out/bin/nvs completion fish > $out/share/fish/vendor_completions.d/nvs.fish
    '';
  };
in
{
  home.packages = [
    nvs
  ];
}
