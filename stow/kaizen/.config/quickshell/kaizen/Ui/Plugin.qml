import Quickshell

// The root of plugins/<name>/Plugin.qml, for each <name>.jsonc in
// ~/.config/kaizen/plugins/. A plugin creates its own Ui.Panel and IpcHandler,
// as the core panels do.
Scope {
    required property var shell
    // Its launcher node is plugins.<name>, which a right-click on a bar button
    // it takes over, or on its indicator, opens.
    required property string name
    // Shaped like Menu.qml's items; merged in load order.
    property var menuItems: ({})
    // Bar buttons it takes over, each mapped to the function its left-click
    // calls. Only "date"; a later plugin wins.
    property var barActions: ({})
    // A bar indicator while set, { label, action, foreground }: left-click calls
    // action. foreground defaults to the bar's text colour.
    property var barIndicator: null
}
