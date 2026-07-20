{
  lib,
  stdenv,
  fetchurl,
}:

let
  pname = "freebuff";
  # BUMP: Latest version refer here -> https://www.npmjs.com/package/freebuff
  version = "0.0.127";

  systems = {
    x86_64-linux = {
      file = "freebuff-linux-x64.tar.gz";
      hash = lib.fakeHash;
    };
    x86_64-linux-baseline = {
      file = "freebuff-linux-x64-baseline.tar.gz";
      hash = lib.fakeHash;
    };
    aarch64-linux = {
      file = "freebuff-linux-arm64.tar.gz";
      hash = lib.fakeHash;
    };
    x86_64-darwin = {
      file = "freebuff-darwin-x64.tar.gz";
      hash = lib.fakeHash;
    };
    aarch64-darwin = {
      file = "freebuff-darwin-arm64.tar.gz";
      hash = "sha256-QfnwX0kxehUYyd1L5DuWfBaK4hcLXeXypJDEEg6sdzM=";
    };
  };

  sys = stdenv.hostPlatform.system;
  platform = systems.${sys} or (throw "Unsupported system: ${sys}");
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/CodebuffAI/codebuff-community/releases/download/freebuff-v${version}/${platform.file}";
    inherit (platform) hash;
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    chmod +x $out/bin/freebuff
  '';

  meta = with lib; {
    description = "The world's strongest free coding agent";
    homepage = "https://freebuff.com";
    license = licenses.mit;
    mainProgram = "freebuff";
    platforms = builtins.attrNames systems;
  };
}
