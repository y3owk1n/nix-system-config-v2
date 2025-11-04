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
  pname = "neru";
  # version = "1.3.0";
  version = "unstable-latest-936e96db319cf873eef595d7ac25ea523d2242a4";
  commitHash = "936e96db319cf873eef595d7ac25ea523d2242a4";

  src = fetchFromGitHub {
    owner = "y3owk1n";
    repo = "neru";
    # tag = "v${finalAttrs.version}";
    rev = "${finalAttrs.commitHash}";
    hash = "sha256-/e0vmKw4AtEwI3MK8BZkd1QVOXqjUuBg9z2Ob+Hlj4c=";
  };

  vendorHash = "sha256-x5NB18fP8ERIB5qeMAMyMnSoDEF2+g+NoJKrC+kIj+k=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/y3owk1n/neru/internal/cli.Version=${finalAttrs.version}"
  ];

  # Completions
  nativeBuildInputs = [
    installShellFiles
    writableTmpDirAsHomeHook
  ];
  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd neru \
      --bash <($out/bin/neru completion bash) \
      --fish <($out/bin/neru completion fish) \
      --zsh <($out/bin/neru completion zsh)
  '';

  passthru = {
    updateScript = nix-update-script { };
  };
})
