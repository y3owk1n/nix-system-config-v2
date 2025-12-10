{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  writeShellScriptBin,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rift";
  version = "0.2.8";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-388XPTrLxKAnx9UAQuciIiekp6heKujHDw4leIYOpDQ=";
  };

  cargoHash = "sha256-A0huWauj3Ltnw39jFft6pyYUVcNK+lu89ZlVQl/aRZg=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    (writeShellScriptBin "sw_vers" ''
      echo 'ProductVersion: ${stdenv.hostPlatform.darwinMinVersion}'
    '')
  ];

  doInstallCheck = false;
})
