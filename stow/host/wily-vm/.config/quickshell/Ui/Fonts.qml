pragma Singleton

import QtQuick
import Quickshell

Singleton {
  // Berkeley Mono is licensed and installed by hand, so pick it only where it
  // is present. qmllint rejects font.families, hence the single resolved name;
  // Qt still falls back per glyph for the Nerd Font icons Berkeley lacks.
  readonly property string mono: Qt.fontFamilies().indexOf("Berkeley Mono") >= 0
    ? "Berkeley Mono"
    : "JetBrainsMono Nerd Font"
}
