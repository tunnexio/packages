{ stdenvNoCC, fetchurl, lib }:
let
  artifacts = {
    x86_64-linux = { arch = "amd64"; sha256 = "a6a87b1e547e97c1b8caedfac71a4c189cd595c867a2747fc3b0b153732fd7bd"; };
    aarch64-linux = { arch = "arm64"; sha256 = "9b9f1dac560853cf3297d25ddcdc77e63d330e0121bfff4f40c5162db650c3e6"; };
  };
  artifact = artifacts.${stdenvNoCC.hostPlatform.system};
in stdenvNoCC.mkDerivation {
  pname = "tunnex-cli";
  version = "0.1.40";
  src = fetchurl {
    url = "https://github.com/tunnexio/tunnex/releases/download/v0.1.40/tnx-linux-${artifact.arch}";
    inherit (artifact) sha256;
  };
  dontUnpack = true;
  dontFixup = true;
  installPhase = ''
    install -Dm755 "$src" "$out/bin/tunnex"
  '';
  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  installCheckPhase = ''
    test "$("$out/bin/tunnex" version)" = "v0.1.40"
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
