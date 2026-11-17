{ stdenvNoCC, fetchurl, lib }:
let
  artifacts = {
    x86_64-linux = { arch = "amd64"; sha256 = "e7f96ab220957aba04a8bb812d40f485844530d8e1f858a7923a142db0f6f18a"; };
    aarch64-linux = { arch = "arm64"; sha256 = "bba5481f4273ab4cca8c9c49ad2194edc228902054a6db11ccb4744ca1cd42cb"; };
  };
  artifact = artifacts.${stdenvNoCC.hostPlatform.system};
in stdenvNoCC.mkDerivation {
  pname = "tunnex-cli";
  version = "0.1.43";
  src = fetchurl {
    url = "https://github.com/tunnexio/tunnex/releases/download/v0.1.43/tnx-linux-${artifact.arch}";
    inherit (artifact) sha256;
  };
  dontUnpack = true;
  dontFixup = true;
  installPhase = ''
    install -Dm755 "$src" "$out/bin/tunnex"
  '';
  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  installCheckPhase = ''
    test "$("$out/bin/tunnex" version)" = "v0.1.43"
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
