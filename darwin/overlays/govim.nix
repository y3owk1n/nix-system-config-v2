{
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  writableTmpDirAsHomeHook,
  lib,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "govim";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "y3owk1n";
    repo = "govim";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mUHFiEsQQjiclkh6QpzQlXQJggaAJqCpYjODyHy3LI0=";
  };

  vendorHash = "sha256-x5NB18fP8ERIB5qeMAMyMnSoDEF2+g+NoJKrC+kIj+k=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/y3owk1n/govim/internal/cli.Version=${finalAttrs.version}"
  ];

  # Completions
  nativeBuildInputs = [
    installShellFiles
    writableTmpDirAsHomeHook
  ];
  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd govim \
      --bash <($out/bin/govim completion bash) \
      --fish <($out/bin/govim completion fish) \
      --zsh <($out/bin/govim completion zsh)
  '';

  passthru = {
    updateScript = nix-update-script { };
  };
})
