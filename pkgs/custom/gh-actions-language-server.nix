{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  nodejs,
}:

let
  pname = "gh-actions-language-server";
  # BUMP: Latest version refer here -> https://www.npmjs.com/package/@actions/languageserver
  version = "0.3.60";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@actions/languageserver/-/languageserver-${version}.tgz";
    hash = "sha256-9MJp1EkCTHiy+0yBHM/hPZPm9Zws+6X/hk0t8bD3TCM=";
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
