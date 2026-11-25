{ stdenvNoCC, fetchurl, lib }:
let
  artifacts = {
    x86_64-linux = { arch = "amd64"; sha256 = "ec1f7729ce8f4b58a87a81e6b9a2a82fb55dd3c30c765235d08b8f50948d2601"; };
    aarch64-linux = { arch = "arm64"; sha256 = "49b024a770426b7350566a710e31c44aa95fd2790f6563a1b36bba5c514d338e"; };
  };
  artifact = artifacts.${stdenvNoCC.hostPlatform.system};
in stdenvNoCC.mkDerivation {
  pname = "tunnex-cli";
  version = "0.1.47";
  src = fetchurl {
    url = "https://github.com/tunnexio/tunnex/releases/download/v0.1.47/tnx-linux-${artifact.arch}";
    inherit (artifact) sha256;
  };
  dontUnpack = true;
  dontFixup = true;
  installPhase = ''
    install -Dm755 "$src" "$out/bin/tunnex"
  '';
  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  installCheckPhase = ''
    test "$("$out/bin/tunnex" version)" = "v0.1.47"
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
