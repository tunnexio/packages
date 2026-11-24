{ stdenvNoCC, fetchurl, lib }:
let
  artifacts = {
    x86_64-linux = { arch = "amd64"; sha256 = "e2726305072d884cc2ec2c2b5a58aeace3a020d1c94982ccdc06b458f4dfb322"; };
    aarch64-linux = { arch = "arm64"; sha256 = "1c9c6880310d34d7a1ad1fcaed6fcba900174eb80fce20ba2947122a5d91fdbc"; };
  };
  artifact = artifacts.${stdenvNoCC.hostPlatform.system};
in stdenvNoCC.mkDerivation {
  pname = "tunnex-cli";
  version = "0.1.46";
  src = fetchurl {
    url = "https://github.com/tunnexio/tunnex/releases/download/v0.1.46/tnx-linux-${artifact.arch}";
    inherit (artifact) sha256;
  };
  dontUnpack = true;
  dontFixup = true;
  installPhase = ''
    install -Dm755 "$src" "$out/bin/tunnex"
  '';
  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  installCheckPhase = ''
    test "$("$out/bin/tunnex" version)" = "v0.1.46"
    "$out/bin/tunnex" help
  '';
  meta = {
    description = "Tunnex Zero Trust command-line client";
    homepage = "https://tunnex.io";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "tunnex";
  };
}
