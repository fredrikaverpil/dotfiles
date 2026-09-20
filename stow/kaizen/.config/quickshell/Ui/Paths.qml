pragma Singleton
import QtQuick
import Quickshell

// The two roots the shell writes under; see "Where the shell writes" in
// KAIZEN.md. The unit's StateDirectory resolves under XDG_STATE_HOME, so the
// same variable decides here.
QtObject {
  readonly property string state: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/kaizen-shell"
  readonly property string cache: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/kaizen-shell"
}
