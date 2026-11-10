import QtQuick
import Quickshell
import Quickshell.Io

import "Ui" as Ui
import "gallery" as Gallery
import "modules/bar/widgets" as BarWidgets
// Unused but for Quickshell, which watches only the files of imported directories.
import "modules/panels/audio" as AudioPanel
import "modules/panels/battery" as BatteryPanel
import "modules/panels/bluetooth" as BluetoothPanel
import "modules/panels/display" as DisplayPanel
import "modules/panels/media" as MediaPanel
import "modules/panels/network" as NetworkPanel
import "Ui/Palette.js" as Palette

// Draws a panel's view in a window, under its bar button, fed by a stand-in in a chosen state.
// Run: qs -p <shell tree>/gallery.qml
ShellRoot {
    id: gallery

    readonly property string ownTree: String(Qt.resolvedUrl(".")).replace(/\/?$/, "/")
    // Another commit's shell tree, as "Now": Quickshell loads no file outside
    // this directory, so it is a copy (see development.md › Panel gallery).
    readonly property string baseTree: ownTree + "gallery/now/"
    readonly property bool hasBase: Qt.createComponent(baseTree + "Ui/PanelCard.qml").status === Component.Ready
    readonly property var panels: ({
            "audio": {
                title: "Audio",
                fake: fakeAudio,
                button: audioButton,
                props: {
                    audio: fakeAudio
                }
            },
            "battery": {
                title: "Battery",
                fake: fakeBattery,
                button: batteryButton,
                props: {
                    service: fakeBattery
                }
            },
            "bluetooth": {
                title: "Bluetooth",
                fake: fakeBluetooth,
                button: bluetoothButton,
                props: {
                    service: fakeBluetooth
                }
            },
            "display": {
                title: "Display",
                fake: fakeDisplay,
                button: displayButton,
                props: {
                    brightness: fakeDisplay,
                    nightlight: fakeDisplay,
                    mirror: fakeDisplay,
                    outputs: fakeDisplay
                }
            },
            "media": {
                title: "Media",
                fake: fakeMedia,
                button: mediaButton,
                props: {
                    service: fakeMedia
                }
            },
            "network": {
                title: "Network",
                fake: fakeNetwork,
                button: networkButton,
                props: {
                    service: fakeNetwork
                }
            }
        })

    property alias panel: saved.panel
    property alias now: saved.now
    property var view: null
    property var card: null

    function treeUrl() {
        return now && hasBase ? baseTree : ownTree;
    }

    function build() {
        if (card)
            card.destroy();
        card = null;
        view = null;
        const tree = treeUrl();
        const cardComponent = Qt.createComponent(tree + "Ui/PanelCard.qml");
        const viewComponent = Qt.createComponent(tree + "modules/panels/" + panel + "/View.qml");
        if (cardComponent.status !== Component.Ready || viewComponent.status !== Component.Ready) {
            console.warn(cardComponent.errorString() + viewComponent.errorString());
            return;
        }
        const newCard = cardComponent.createObject(scene, {
            shell: fakeShell
        });
        const newView = viewComponent.createObject(newCard.body, Object.assign({
            shell: fakeShell
        }, panels[panel].props));
        newCard.width = Qt.binding(() => newView.cardWidth);
        newCard.height = Qt.binding(() => newView.cardHeight);
        newCard.keyNavigation = Qt.binding(() => !!newView.keyNavigation);
        if (newView.cardPadding !== undefined)
            newCard.padding = Qt.binding(() => newView.cardPadding);
        card = newCard;
        view = newView;
        const variant = JSON.parse(saved.variants)[panel];
        if (newView.variants && newView.variants.indexOf(variant) >= 0)
            newView.variant = variant;
        focusView();
    }

    function focusView() {
        if (!view)
            return;
        if (view.reset)
            view.reset();
        if (card.keyNavigation)
            card.focusContent();
    }

    function applyScenario(name) {
        const fake = panels[panel].fake;
        const values = fake.scenarios[name];
        if (!values)
            return false;
        for (const key in values)
            fake[key] = values[key];
        fake.scenario = name;
        saved.scenarios = JSON.stringify(Object.assign(JSON.parse(saved.scenarios), {
            [panel]: name
        }));
        return true;
    }

    function setVariant(name) {
        if (!view || !view.variants || view.variants.indexOf(name) < 0)
            return false;
        view.variant = name;
        saved.variants = JSON.stringify(Object.assign(JSON.parse(saved.variants), {
            [panel]: name
        }));
        return true;
    }

    onPanelChanged: if (loaded)
        build()
    onNowChanged: if (loaded)
        build()

    property bool loaded: false

    // Survives the reload that follows each saved edit.
    PersistentProperties {
        id: saved

        reloadableId: "gallery"

        property string panel: "audio"
        property bool now: false
        property bool dark: true
        // JSON: panel name to scenario or variant name.
        property string scenarios: "{}"
        property string variants: "{}"

        onLoaded: {
            const scenarios = JSON.parse(saved.scenarios);
            const current = gallery.panel;
            for (const name in gallery.panels) {
                if (scenarios[name]) {
                    gallery.panel = name;
                    gallery.applyScenario(scenarios[name]);
                }
            }
            gallery.panel = current;
            gallery.loaded = true;
            gallery.build();
        }
    }

    // What a view reads from the shell.
    QtObject {
        id: fakeShell

        property alias dark: saved.dark
        property real textScale: 1
        readonly property var batteryService: fakeBattery
        readonly property var palette: dark ? Palette.dark : Palette.light

        function setDark(on) {
            dark = on;
        }

        function setTextScale(value) {
            textScale = value;
        }
    }

    Gallery.FakeAudio {
        id: fakeAudio

        property string scenario: "Playing"
    }

    Gallery.FakeBattery {
        id: fakeBattery

        property string scenario: "78% on battery"
    }

    Gallery.FakeBluetooth {
        id: fakeBluetooth

        property string scenario: "Connected"
    }

    Gallery.FakeDisplay {
        id: fakeDisplay

        property string scenario: "Laptop"
    }

    Gallery.FakeMedia {
        id: fakeMedia

        property string scenario: "Playing"
    }

    Gallery.FakeNetwork {
        id: fakeNetwork

        property string scenario: "Wi-Fi"
    }

    // The bar's own buttons, bound to the stand-ins.
    Component {
        id: audioButton

        BarWidgets.AudioButton {
            shell: fakeShell
            audio: fakeAudio
        }
    }

    Component {
        id: batteryButton

        BarWidgets.BatteryButton {
            shell: fakeShell
            service: fakeBattery
        }
    }

    Component {
        id: bluetoothButton

        BarWidgets.BluetoothButton {
            shell: fakeShell
            service: fakeBluetooth
        }
    }

    Component {
        id: displayButton

        BarWidgets.DisplayButton {
            shell: fakeShell
        }
    }

    Component {
        id: mediaButton

        BarWidgets.MediaButton {
            shell: fakeShell
            service: fakeMedia
        }
    }

    Component {
        id: networkButton

        BarWidgets.NetworkButton {
            shell: fakeShell
            service: fakeNetwork
        }
    }

    IpcHandler {
        target: "gallery"

        function panel(panel: string): string {
            if (!gallery.panels[panel])
                return "unknown panel: " + Object.keys(gallery.panels).join(", ");
            gallery.panel = panel;
            return panel;
        }
        function scenario(name: string): string {
            return gallery.applyScenario(name) ? name : "unknown scenario: " + Object.keys(gallery.panels[gallery.panel].fake.scenarios).join(", ");
        }
        function variant(name: string): string {
            return gallery.setVariant(name) ? name : "unknown variant";
        }
        function reload(): void {
            Quickshell.reload(false);
        }
        function theme(dark: bool): void {
            fakeShell.dark = dark;
        }
        function now(on: bool): void {
            gallery.now = on;
        }
        // Saves the stage as a PNG once drawn; returns the path.
        function shot(path: string): string {
            stage.grabToImage(result => result.saveToFile(path));
            return path;
        }
    }

    FloatingWindow {
        id: window

        title: "kaizen gallery"
        implicitWidth: 760
        implicitHeight: 680
        color: fakeShell.palette.bg

        Column {
            id: controls

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 8

            Choices {
                colors: fakeShell.palette
                onPicked: gallery.focusView()
                model: Object.keys(gallery.panels).map(key => ({
                            label: gallery.panels[key].title,
                            chosen: gallery.panel === key,
                            pick: () => gallery.panel = key
                        }))
            }

            Choices {
                colors: fakeShell.palette
                onPicked: gallery.focusView()
                visible: gallery.hasBase
                model: [
                    {
                        label: "Now",
                        chosen: gallery.now,
                        pick: () => gallery.now = true
                    },
                    {
                        label: "Proposal",
                        chosen: !gallery.now,
                        pick: () => gallery.now = false
                    }
                ]
            }

            Choices {
                colors: fakeShell.palette
                onPicked: gallery.focusView()
                readonly property var fake: gallery.panels[gallery.panel].fake
                model: Object.keys(fake.scenarios).map(name => ({
                            label: name,
                            chosen: fake.scenario === name,
                            pick: () => gallery.applyScenario(name)
                        }))
            }

            Choices {
                colors: fakeShell.palette
                onPicked: gallery.focusView()
                readonly property var variants: gallery.view && gallery.view.variants ? gallery.view.variants : []
                visible: variants.length > 0
                model: variants.map(name => ({
                            label: name,
                            chosen: gallery.view.variant === name,
                            pick: () => gallery.setVariant(name)
                        }))
            }

            Choices {
                colors: fakeShell.palette
                onPicked: gallery.focusView()
                model: [
                    {
                        label: "Dark",
                        chosen: fakeShell.dark,
                        pick: () => fakeShell.dark = true
                    },
                    {
                        label: "Light",
                        chosen: !fakeShell.dark,
                        pick: () => fakeShell.dark = false
                    }
                ]
            }
        }

        Rectangle {
            id: stage

            anchors.top: controls.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            radius: 8
            color: fakeShell.dark ? Qt.darker(fakeShell.palette.bg, 1.4) : Qt.darker(fakeShell.palette.bg, 1.06)

            // Gives the keyboard back to the view after a click on the controls.
            MouseArea {
                anchors.fill: parent
                onClicked: gallery.focusView()
            }

            // A piece of the bar, then the card, which build() adds.
            Column {
                id: scene

                anchors.centerIn: parent
                spacing: 16

                Rectangle {
                    width: gallery.card ? gallery.card.width : 0
                    height: Math.round(32 * fakeShell.textScale)
                    color: fakeShell.palette.bg

                    Loader {
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        sourceComponent: gallery.panels[gallery.panel].button
                    }
                }
            }
        }
    }

    // A row of buttons, one of them chosen.
    component Choices: Row {
        id: choices

        property var model: []
        required property var colors

        signal picked

        width: parent.width
        spacing: 8

        Repeater {
            model: choices.model

            delegate: Rectangle {
                required property var modelData

                width: (choices.width - choices.spacing * (choices.model.length - 1)) / choices.model.length
                height: 30
                radius: 4
                color: modelData.chosen || hover.containsMouse ? choices.colors.sel : "transparent"
                border.color: modelData.chosen ? choices.colors.fg : choices.colors.dim
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    color: choices.colors.fg
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 13
                    text: parent.modelData.label
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    // Picking rebuilds the model and with it this delegate, so last.
                    onClicked: {
                        const pick = parent.modelData.pick;
                        choices.picked();
                        pick();
                    }
                }
            }
        }
    }
}
