pragma Singleton

import QtQuick
import Quickshell

Singleton {
  // KAIZEN_FONT (programs.kaizen.font) may be licensed and installed by hand,
  // so pick it only where it is present. qmllint rejects font.families, hence
  // the single resolved name; Qt still falls back per glyph for the Nerd Font
  // icons it lacks.
  readonly property string mono: {
    const font = Quickshell.env("KAIZEN_FONT")
    return Qt.fontFamilies().indexOf(font) >= 0 ? font : "JetBrainsMono Nerd Font"
  }
}
