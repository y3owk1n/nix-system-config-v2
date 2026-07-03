{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  nodejs,
}:

let
  pname = "gh-actions-language-server";
  version = "0.3.58";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@actions/languageserver/-/languageserver-${version}.tgz";
    hash = "sha256-H7td6s74NdcIdMzCGpU1Mh2xT3bZPMUw5dw92VepLZY=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib/node_modules/gh-actions-language-server
    tar -xzf $src -C $out/lib/node_modules/gh-actions-language-server --strip-components=1

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/gh-actions-language-server \
      --add-flags "$out/lib/node_modules/gh-actions-language-server/bin/actions-languageserver"
  '';

  meta = with lib; {
    description = "Language server for GitHub Actions workflow files";
    homepage = "https://github.com/actions/languageservices";
    license = licenses.mit;
    mainProgram = "gh-actions-language-server";
  };
}
