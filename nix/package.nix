{ stdenvNoCC, fetchurl, lib }:
let
  artifacts = {
    x86_64-linux = { arch = "amd64"; sha256 = "e5f582ced11ebda02eb8d3911188669fcc630f15fcac3e673fe91c0b913f9ae1"; };
    aarch64-linux = { arch = "arm64"; sha256 = "15444872a11af86fe399bc61e80cf3921e7e4d8a4d9cbc4cfa56b3af718d85f0"; };
  };
  artifact = artifacts.${stdenvNoCC.hostPlatform.system};
in stdenvNoCC.mkDerivation {
  pname = "tunnex-cli";
  version = "0.1.41";
  src = fetchurl {
    url = "https://github.com/tunnexio/tunnex/releases/download/v0.1.41/tnx-linux-${artifact.arch}";
    inherit (artifact) sha256;
  };
  dontUnpack = true;
  dontFixup = true;
  installPhase = ''
    install -Dm755 "$src" "$out/bin/tunnex"
  '';
  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  installCheckPhase = ''
    test "$("$out/bin/tunnex" version)" = "v0.1.41"
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
