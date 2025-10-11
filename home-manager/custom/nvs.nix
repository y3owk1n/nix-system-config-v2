{
  pkgs,
  ...
}:

let
  system = pkgs.system;

  version = "1.10.7";

  nvsInfo = {
    "x86_64-linux" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-linux-amd64";
      # use `nix hash convert --hash-algo sha256 <checksum>`
      # even better "awk '{print $1}' <checksum> | xargs nix hash convert --hash-algo sha256"
      sha256 = "sha256-oxR8eVtCr8RGyDy8w63xxrpsvEQnk78ll3N0I7eAgsA=";
    };
    "aarch64-linux" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-linux-arm64";
      sha256 = "sha256-z9GBFC/h2EyimEDeJ1TdaL48R/myppp2wDus2vTpSt0=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-darwin-amd64";
      sha256 = "sha256-jGEllbTI69Uvqw2fix9381RnXs7xlUVTi8o6+cAbHXg=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/y3owk1n/nvs/releases/download/v${version}/nvs-darwin-arm64";
      sha256 = "sha256-qGv0DzXDVu/UAhHEFrKLNzVRxB4hucdYJkOQOefoJ50=";
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
    # build tools
    pkgs.ninja
    pkgs.cmake
    pkgs.gettext
  ];
}
