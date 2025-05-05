{ pkgs, ... }:

let
  rev = "8eacf1f6704e285f8f26c4b522326c6172b3c9fe";
  version = "unstable-${rev}"; # You can use just rev or format it like this
  starship-jj = pkgs.rustPlatform.buildRustPackage rec {
    pname = "starship-jj";
    inherit version;

    src = pkgs.fetchgit {
      url = "https://gitlab.com/lanastara_foss/starship-jj.git";
      inherit rev;
      sha256 = "sha256-ss2aV6H5+zwczZrE01lf8S9N1UQZYGanrD5MySzaDgQ="; # replace after running once to get actual hash
    };

    cargoHash = "sha256-8OIZecqfG8n1XphLWlllnbxjf5gJs7htVAUStxCJXes="; # <-- you'll fix this below

    # Optional, if it requires additional build inputs
    nativeBuildInputs = with pkgs; [ pkg-config ];

    buildInputs = with pkgs; [
      openssl
    ];

    doCheck = false; # disable if tests fail or are not present
  };
in
{
  environment.systemPackages = [
    starship-jj
  ];
}
