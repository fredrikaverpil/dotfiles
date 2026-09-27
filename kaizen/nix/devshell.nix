# QML tooling and the kaizen check tasks. Tasks run in kaizen/shell of the
# enclosing checkout, or in $KAIZEN_SHELL when set (flake checks).
{
  lib,
  stdenv,
  mkShell,
  writeShellScriptBin,
  qt6,
  # Only its lib/qt-6/qml (.qmltypes) is used.
  quickshell,
  niri,
  jq,
  # Test dirs outside kaizen that qml-test also runs, relative to the checkout
  # root: plugins kept in the user's own repo.
  extraTests ? [ ],
}:
let
  task =
    name: text:
    writeShellScriptBin name ''
      set -e
      cd "''${KAIZEN_SHELL:-$(git rev-parse --show-toplevel)/kaizen/shell}"
      ${text}
    '';
in
mkShell {
  packages = [
    qt6.qtdeclarative # qmlls, qmllint, qmlformat, qmltestrunner
    (task "qml-lint" "qmllint -E -W 0 $(find . -name '*.qml')")
    (task "qml-test" ''
      export QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME=
      qmltestrunner -input tests
      ${lib.concatMapStrings (dir: ''
        qmltestrunner -input "$(git rev-parse --show-toplevel)/${dir}"
      '') extraTests}
    '')
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    niri
    jq
    (task "compositor-test" "bash tests/config_test.sh")
    (task "shell-smoke" "tests/shell_smoke.sh \"$@\"")
    (task "shell-perf" "tests/shell_perf.sh \"$@\"")
  ];
  # qmlls/qmllint/qmltestrunner take import paths from argv or env only (`-E`
  # reads this); .qmlls.ini has no key for them.
  QML_IMPORT_PATH = "${quickshell}/lib/qt-6/qml:${qt6.qtdeclarative}/lib/qt-6/qml";
}
