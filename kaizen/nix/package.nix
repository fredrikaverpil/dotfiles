# The QML tree, the niri includes, the `kaizen` launcher, `kaizen-focus`, and
# `kaizen-shell`, which runs the tree as Quickshell config "kaizen".
{
  lib,
  stdenvNoCC,
  makeWrapper,
  runCommand,
  python3,
  quickshell,
  qt6,
  unicode-emoji,
  jq,
  niri,
  dconf,
  xdg-utils,
  wl-clipboard,
  libnotify,
  iproute2,
  iputils,
  uwsm,
  xdg-terminal-exec,
  pipewire,
  mpv,
  grim,
  gpu-screen-recorder,
  satty,
  imagemagick,
  kdePackages,
  curl,
  wl-gammarelay-rs,
  bluetui,
  networkmanager,
  networkmanagerapplet,
  glibc,
}:
let
  # What the shell runs. Suffixed onto PATH, so the host's own win, such as the
  # setcap gpu-screen-recorder and ping wrappers.
  runtime = [
    niri
    dconf
    xdg-utils
    wl-clipboard
    libnotify
    iproute2
    iputils
    uwsm
    xdg-terminal-exec
    pipewire
    mpv
    grim
    gpu-screen-recorder
    satty
    imagemagick
    kdePackages.kconfig
    curl
    jq
    wl-gammarelay-rs
    bluetui
    networkmanager
    networkmanagerapplet
    # zdump
    glibc.bin
  ];

  # Shortcode -> emoji, for apps (Slack) that send `:name:` in notification text.
  emoji-shortcodes =
    runCommand "emoji-shortcodes.json"
      { nativeBuildInputs = [ (python3.withPackages (p: [ p.emoji ])) ]; }
      ''
        python3 - > $out <<'EOF'
        import json, emoji
        codes = {}
        for char, data in emoji.EMOJI_DATA.items():
            for name in [data["en"], *data.get("alias", [])]:
                codes.setdefault(name.strip(":"), char)
        for tone, char in enumerate("🏻🏼🏽🏾🏿", start=2):
            codes[f"skin-tone-{tone}"] = char
        json.dump(codes, open(1, "w", encoding="utf-8", closefd=False), ensure_ascii=False)
        EOF
      '';
in
stdenvNoCC.mkDerivation {
  pname = "kaizen";
  version = "0-unstable";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../bin
      ../niri
      (lib.fileset.difference ../shell ../shell/tests)
    ];
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/kaizen
    cp -r shell niri $out/share/kaizen
    install -Dm755 -t $out/bin bin/*
    wrapProgram $out/bin/kaizen-focus --prefix PATH : ${lib.makeBinPath [ jq ]}
    # qtimageformats supplies Quickshell's WebP decoder.
    # The menu's emoji picker reads names from Unicode's test file.
    makeWrapper ${quickshell}/bin/quickshell $out/bin/kaizen-shell \
      --add-flags "-c kaizen" \
      --set QT_PLUGIN_PATH ${qt6.qtimageformats}/lib/qt-6/plugins \
      --set EMOJI_TEST ${unicode-emoji}/share/unicode/emoji/emoji-test.txt \
      --set EMOJI_SHORTCODES ${emoji-shortcodes} \
      --suffix PATH : ${lib.makeBinPath runtime}
    runHook postInstall
  '';

  meta = {
    description = "niri + Quickshell desktop";
    homepage = "https://github.com/fredrikaverpil/dotfiles/tree/main/kaizen";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "kaizen";
  };
}
