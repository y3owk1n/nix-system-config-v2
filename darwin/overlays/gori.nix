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
  pname = "gori";
  version = "unstable-2025-10-28";

  src = fetchFromGitHub {
    owner = "y3owk1n";
    repo = "gori";
    # tag = "v${finalAttrs.version}";
    rev = "51cdd97546c419897c61767f444f9a452ad93221";
    hash = "sha256-jIVty8CD0ep95jWYuKxPYHF00GwcPgoD9OUZ++PRSv0=";
  };

  vendorHash = "sha256-faXkl+hoDvJRTdwD8J9IOY0rRT89Bo8OrmwmPccxlj4=";

  # Completions
  nativeBuildInputs = [
    installShellFiles
    writableTmpDirAsHomeHook
  ];
  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd gori \
      --bash <($out/bin/gori completion bash) \
      --fish <($out/bin/gori completion fish) \
      --zsh <($out/bin/gori completion zsh)
  '';

  passthru = {
    updateScript = nix-update-script { };
  };

})
