{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

let
  # BUMP: Latest version refer here -> https://github.com/tw93/Mole/releases/latest
  version = "1.51.0";
in
buildGoModule {
  pname = "mole";
  inherit version;

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "Mole";
    rev = "V${version}";
    sha256 = "sha256-HJ2q3/H5s2I3hMPNOh0meNT0Ay5VFlsDIX//QZjRE4k=";
  };

  vendorHash = "sha256-Q7VzGJ1bGAyMi2Ih3LvI92lCVqxKIyr7H89LAFczNbo=";

  buildPhase = ''
    runHook preBuild
    mkdir -p bin
    go build -trimpath -ldflags "-s -w -X main.Version=${version} -X main.BuildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" -o bin/analyze-go ./cmd/analyze
    go build -trimpath -ldflags "-s -w -X main.Version=${version} -X main.BuildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" -o bin/status-go ./cmd/status
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/libexec $out/bin
    cp -r bin lib $out/libexec/
    substituteInPlace mole \
      --replace-fail 'SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"' \
                     "SCRIPT_DIR='$out/libexec'"
    install -m755 mole $out/bin/
    ln -s mole $out/bin/mo
    runHook postInstall
  '';

  meta = with lib; {
    description = "Deep clean and optimize your Mac";
    homepage = "https://mole.fit";
    license = licenses.gpl3Only;
    platforms = platforms.darwin;
    mainProgram = "mole";
  };
}
