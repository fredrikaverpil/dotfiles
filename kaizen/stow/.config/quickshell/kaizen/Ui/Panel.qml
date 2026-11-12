import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: panel

    required property var shell
    property bool shown: false
    property int cardWidth: 600
    property int cardHeight: 420
    readonly property int barHeight: shell ? shell.barHeight : 32

    property bool keyNavigation: false
    property bool focusPrimed: false

    default property alias content: card.content
    readonly property alias contentSpacing: card.contentSpacing

    function open() {
        if (shell && shell.registerPanel)
            shell.registerPanel(panel);
        if (shell && shell.claimPanel)
            shell.claimPanel(panel);
        shown = true;
    }

    function close() {
        shown = false;
    }

    function toggle() {
        shown ? close() : open();
    }

    onShownChanged: {
        focusPrimed = false;
        if (shown && keyNavigation)
            card.focusContent();
    }
    Component.onCompleted: if (shell && shell.registerPanel)
        shell.registerPanel(panel)

    visible: shown
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusiveZone: 0
    color: "transparent"
    mask: modalMask
    WlrLayershell.layer: WlrLayer.Overlay
    // Exclusive to take the keyboard, then on-demand between panels where the
    // compositor keeps focus through the demotion.
    WlrLayershell.keyboardFocus: shown ? (focusPrimed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None

    data: [
        Timer {
            interval: 75
            running: panel.shown && !panel.focusPrimed && Compositor.releaseExclusiveFocus
            onTriggered: panel.focusPrimed = true
        },
        Region {
            id: modalMask
            item: modalInput

            Region {
                width: panel.width
                height: panel.barHeight
                intersection: Intersection.Subtract
            }
        },
        Item {
            id: modalInput
            anchors.fill: parent
        },
        MouseArea {
            anchors.fill: parent
            enabled: panel.shown
            onClicked: panel.close()
        },
        PanelCard {
            id: card
            shell: panel.shell
            keyNavigation: panel.keyNavigation
            anchors.centerIn: parent
            width: panel.cardWidth
            height: panel.cardHeight
            // Follows the text size, capped to stay clear of the bar and screen edges.
            // The floor is 1, or the text size when that is smaller.
            scale: Math.max(Math.min(1, panel.shell ? panel.shell.textScale : 1), Math.min(panel.shell ? panel.shell.textScale : 1, (panel.width - 32) / panel.cardWidth, (panel.height - 2 * panel.barHeight - 32) / panel.cardHeight))
            onCloseRequested: panel.close()
        }
    ]
}
