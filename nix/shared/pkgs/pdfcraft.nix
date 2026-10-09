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
  wayland,
  libx11,
  libxcursor,
  libxi,
}:
let
  # Loaded with dlopen, so autoPatchelfHook does not see them.
  runtimeLibs = [
    dbus
    libGL
    libxkbcommon
    wayland
    libx11
    libxcursor
    libxi
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "pdfcraft";
  version = "0.4.0";

  src = fetchurl {
    url = "https://github.com/storytold/pdfcraft/releases/download/v${finalAttrs.version}/pdfcraft-${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256-SHmzzbTRJhlFrwOxxfAPPoaNBehOd5EZYMrFBaoWwds=";
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
    description = "Clean-room reimplementation of Adobe Acrobat in Rust";
    homepage = "https://github.com/storytold/pdfcraft";
    license = with lib.licenses; [
      mit
      asl20
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "pdfcraft";
  };
})
