# Prebuilt release; not in nixpkgs and the repo has no flake.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  dbus,
  libGL,
  libxkbcommon,
  vulkan-loader,
  wayland,
  libx11,
  libxcb,
  libxcursor,
  libxi,
}:
let
  # Loaded with dlopen, so autoPatchelfHook does not see them.
  runtimeLibs = [
    dbus
    libGL
    libxkbcommon
    vulkan-loader
    wayland
    libx11
    libxcursor
    libxi
    libxcb
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "photocraft";
  version = "0.5.0";

  src = fetchurl {
    url = "https://github.com/storytold/photocraft/releases/download/v${finalAttrs.version}/photocraft-${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256-4EQQGy2lUiiW4dgza4EIfL7L9reLdoUxX1jdTz36TOA=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r bin share $out/
    for f in $out/bin/*; do
      wrapProgram "$f" --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
    done
    runHook postInstall
  '';

  meta = {
    description = "Clean-room reimplementation of Adobe Photoshop in Rust";
    homepage = "https://github.com/storytold/photocraft";
    license = with lib.licenses; [
      mit
      asl20
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "photocraft";
  };
})
