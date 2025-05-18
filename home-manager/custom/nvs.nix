{
  config,
  pkgs,
  lib,
  ...
}:

let
  system = pkgs.system;

  version = "1.10.5";

  inherit (lib) mkIf;
  nvsInfo = {
    "x86_64-linux" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-linux-amd64";
      # use `nix hash convert --hash-algo sha256 <checksum>`
      # even better "awk '{print $1}' <checksum> | xargs nix hash convert --hash-algo sha256"
      sha256 = "sha256-HPugwWrTrxccc65rxIQRaq+dW9y72Wc1luZYO7/5KCg=";
    };
    "aarch64-linux" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-linux-arm64";
      sha256 = "sha256-/BllKa4/gabfJYzw1FSAsm/KONq/x6qWDh2+jvPWJ7Q=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-darwin-amd64";
      sha256 = "sha256-hdpCrd4K0Hi//Qlh2MH7hK56Z2OirETZwwxefQVTvvM=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-darwin-arm64";
      sha256 = "sha256-GsYaBxoU8KBCj1wzFss8Iqs/Tz34jtGrHAMQedX9uuI=";
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
    '';
  };
in
{
  home.packages = [
    nvs
  ];
}
