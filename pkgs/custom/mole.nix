{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

let
  version = "1.45.0";
in
buildGoModule {
  pname = "mole";
  inherit version;

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "Mole";
    rev = "V${version}";
    sha256 = "sha256-8Crhqk8r8Xj+Lc2IpF4NCU8nkn/QH4gOPs4EUsfzQSw=";
  };

  vendorHash = "sha256-HcCJ3DYj5AXX+E5AD6jxBysCq4TAoIs2I6oVN4dCBxQ=";

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
