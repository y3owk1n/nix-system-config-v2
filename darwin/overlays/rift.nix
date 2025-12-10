{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  writeShellScriptBin,
}:
let
  rev = "eae4229d2a82fdd2529f0b7ff7daa097845f07b0";
  shortHash = lib.substring 0 7 rev;
  pversion = "main-${shortHash}";
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rift";
  version = pversion;

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = rev;
    # rev = "v${finalAttrs.version}";
    sha256 = "sha256-OFGh7b8aH7F8sdMpidgEKmnueuxtnnNB/5wKZE6XzsM=";
  };

  cargoHash = "sha256-A0huWauj3Ltnw39jFft6pyYUVcNK+lu89ZlVQl/aRZg=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    (writeShellScriptBin "sw_vers" ''
      echo 'ProductVersion: ${stdenv.hostPlatform.darwinMinVersion}'
    '')
  ];

  doInstallCheck = false;
})
