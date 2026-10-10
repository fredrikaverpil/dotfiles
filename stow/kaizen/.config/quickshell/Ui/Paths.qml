pragma Singleton
import QtCore
import QtQuick
import Quickshell

// The root the shell reads its config from, the two it writes under (see
// "Where the shell writes" in docs/kaizen/README.md), and its emoji data. The
// unit's StateDirectory resolves under XDG_STATE_HOME, so the same variable
// decides here.
QtObject {
    readonly property string config: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/kaizen"
    readonly property string state: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/kaizen-shell"
    readonly property string cache: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/kaizen-shell"
    // kaizen-emoji's output, first match in the XDG data dirs; empty when none.
    readonly property string emoji: String(StandardPaths.locate(StandardPaths.GenericDataLocation, "kaizen/emoji.json")).replace(/^file:\/\//, "")
}
