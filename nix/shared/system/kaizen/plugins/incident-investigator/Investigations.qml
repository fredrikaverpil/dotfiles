import QtQuick
import Quickshell
import Quickshell.Io

import qs.Ui as Ui
import "Actions.js" as Actions
import "Format.js" as Format

// The window's content: the list of investigations and the selected one.
Column {
    id: root

    required property var shell

    signal paletteRequested(var keys)

    spacing: 8

    // The daemon's state dir; `investigate serve` writes it, the window only reads it.
    readonly property string stateDir: Ui.Paths.state + "/plugins/incident-investigator"
    property var all: []
    property var projects: []
    // The configured tags, { name, color }; the daemon writes them into settings.json.
    property var tags: []
    // A tag's name, "" for all.
    property string tagFilter: ""
    // [] for every project.
    property var projectFilter: []
    property string query: ""
    property string selectedId: ""
    // What the next run starts with; the daemon owns them.
    property string model: Format.models[0]
    property string effort: "high"
    // Dragged with the divider.
    property real listWidth: 170
    // The projects the investigations name, for the filter.
    readonly property var listedProjects: [...new Set(all.reduce((names, item) => names.concat(item.projects), []))].sort()
    readonly property var items: all.filter(item => (!tagFilter || item.tag === tagFilter) && (!projectFilter.length || item.projects.some(project => projectFilter.includes(project))) && Format.matches(item, query))
    readonly property var current: items.find(item => item.id === selectedId) || null

    // The selection as last loaded. It outlives a deleted or filtered-out selection,
    // so the view being torn down never reads null.
    property var shown: null
    // Assigned, not bound: a reload that keeps the selection and its kind leaves
    // the view, its scroll and its typed text alone.
    property string formId: ""
    property string detailId: ""
    onCurrentChanged: {
        if (current)
            shown = current;
        const draft = current !== null && current.status === "draft";
        formId = draft ? current.id : "";
        detailId = current !== null && !draft ? current.id : "";
    }

    // Ids picked with shift or ctrl; two or more can be combined into a new investigation.
    property var picked: []
    readonly property var pickedItems: items.filter(item => picked.indexOf(item.id) >= 0)
    onSelectedIdChanged: picked = []

    // A plain click selects, shift extends from the selection to index, ctrl toggles.
    function click(index, modifiers) {
        const id = items[index].id;
        if (modifiers & Qt.ShiftModifier) {
            const from = Math.max(0, items.findIndex(item => item.id === selectedId));
            picked = items.slice(Math.min(from, index), Math.max(from, index) + 1).map(item => item.id);
        } else if (modifiers & Qt.ControlModifier) {
            const base = picked.length ? picked : [selectedId];
            picked = base.indexOf(id) >= 0 ? base.filter(other => other !== id) : base.concat([id]);
        } else {
            picked = [];
            selectedId = id;
        }
    }

    // Space on a row: toggles it in the picked set, which starts from the selection.
    function togglePick(id) {
        if (!picked.length && id === selectedId) {
            picked = [id];
        } else {
            const base = picked.length ? picked : [selectedId];
            picked = base.indexOf(id) >= 0 ? base.filter(other => other !== id) : base.concat([id]);
        }
    }

    // Running ones stay; cancel them first.
    readonly property var deletable: pickedItems.filter(item => item.status !== "running")

    function deletePicked() {
        deleteItems(deletable.map(item => item.id));
    }

    // Removes the investigations; the selection moves to the nearest one left.
    function deleteItems(gone) {
        const index = items.findIndex(item => item.id === selectedId);
        const rest = items.filter(item => gone.indexOf(item.id) < 0);
        if (gone.indexOf(selectedId) >= 0)
            selectedId = rest.length ? rest[Math.min(index, rest.length - 1)].id : "";
        picked = [];
        run(["delete"].concat(gone));
    }

    // The ids that Backspace on a row asks to delete; empty when not asking.
    property var confirmingDelete: []

    // Backspace deletes the picked rows, or else the focused one; running ones stay.
    function askDelete(id) {
        const ids = (picked.length ? picked : [id]).filter(other => items.some(item => item.id === other && item.status !== "running"));
        if (!ids.length)
            return;
        confirmingDelete = ids;
        listBar.forceActiveFocus();
    }

    function answerDelete(yes) {
        const ids = confirmingDelete;
        confirmingDelete = [];
        if (yes)
            deleteItems(ids);
        Qt.callLater(focusSelected);
    }

    function combinePicked() {
        run(["combine"].concat(pickedItems.map(item => item.id)));
        picked = [];
    }

    // Running ones stay; cancel them first.
    readonly property var clearable: items.filter(item => item.status !== "running")
    readonly property string clearLabel: projectFilter.length || query ? "Clear listed" : tagFilter ? "Clear " + tagFilter : "Clear all"
    property bool confirmingClear: false

    // A draft with the filtered tag, so the filter lists it.
    function draft() {
        run(tagFilter ? ["draft", "-tag=" + tagFilter] : ["draft"]);
    }

    // The palette's rows.
    readonly property var actions: Actions.actions({
        current: current,
        picked: pickedItems,
        deletable: deletable.length,
        clearable: clearable.length,
        clearLabel: clearLabel,
        tags: tags,
        model: model,
        effort: effort,
        tagFilter: tagFilter,
        projectFilter: projectFilter,
        projects: listedProjects
    })

    // Runs a palette row's action on the selection, or on the picked set.
    function runAction(action, arg) {
        const form = formView.count ? formView.itemAt(0) : null;
        const detail = detailView.count ? detailView.itemAt(0) : null;
        if (action === "run" && form)
            form.start();
        else if (action === "discard" && form)
            form.discard();
        else if (action === "stop")
            run(["cancel", current.id]);
        else if (action === "rerun")
            run(["start", current.id]);
        else if (action === "followUp" && detail)
            detail.followUp();
        else if (action === "terminal")
            terminal(current);
        else if (action === "copy")
            copy(arg);
        else if (action === "tag" && form)
            form.tag = arg;
        else if (action === "tag")
            run(["tag", current.id].concat(arg ? [arg] : []));
        else if (action === "delete")
            askDelete(selectedId);
        else if (action === "combine")
            combinePicked();
        else if (action === "unpick")
            picked = [];
        else if (action === "new")
            draft();
        else if (action === "clear")
            confirmingClear = true;
        else if (action === "model")
            run(["settings", "-model=" + arg]);
        else if (action === "effort")
            run(["settings", "-effort=" + arg]);
        else if (action === "filterTag")
            tagFilter = arg;
        else if (action === "filterProject")
            projectFilterBox.toggle(arg);
    }

    Keys.onPressed: event => {
        if (event.key !== Qt.Key_Question)
            return;
        paletteRequested(["?"]);
        event.accepted = true;
    }

    // What the last command printed on stderr: its error, if it failed.
    property string error: ""
    property var queue: []

    // Runs `investigate` verbs one at a time, so a draft's edit lands before its start.
    function run(args) {
        queue = queue.concat([args]);
        if (!cli.running)
            next();
    }

    function next() {
        if (!queue.length)
            return;
        cli.command = ["investigate"].concat(queue[0]);
        queue = queue.slice(1);
        cli.running = true;
    }

    function remove(id) {
        const index = items.findIndex(item => item.id === id);
        const rest = items.filter(item => item.id !== id);
        const next = rest[Math.min(index, rest.length - 1)];
        selectedId = next ? next.id : "";
        run(["delete", id]);
    }

    // Clears what the filter lists.
    function clearListed() {
        const gone = clearable.map(item => item.id);
        const rest = items.filter(item => gone.indexOf(item.id) < 0);
        selectedId = rest.length ? rest[0].id : "";
        confirmingClear = false;
        run(["delete"].concat(gone));
    }

    // Opens `claude --resume` where the daemon ran it: sessions are stored per cwd,
    // under the profile the run recorded.
    function terminal(item) {
        Quickshell.execDetached(["xdg-terminal-exec", "--dir=" + stateDir + "/" + item.id, "--", "env", "CLAUDE_CONFIG_DIR=" + item.claudeConfigDir, "claude", "--resume", item.sessionId]);
    }

    // The Selectable holding the selection; a new selection clears the previous one.
    property Item selection: null
    // The Selectable whose copy menu is open, and where it opened in window coordinates.
    property Item menuEdit: null
    property point menuAt

    function copy(text) {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    // Moves the selection by delta through the list and focuses its row; with rows picked, only the focus
    // moves, so the picks stay.
    function step(delta) {
        const index = (picked.length ? list.currentIndex : items.findIndex(item => item.id === selectedId)) + delta;
        if (index < 0 || index >= items.length)
            return;
        if (!picked.length)
            selectedId = items[index].id;
        focusRow(index);
    }

    // Focuses the selected row, if the filter lists it.
    function focusSelected() {
        const index = items.findIndex(item => item.id === selectedId);
        if (index >= 0)
            focusRow(index);
    }

    function focusRow(index) {
        list.positionViewAtIndex(index, ListView.Contain);
        const row = list.itemAtIndex(index);
        if (row)
            row.forceActiveFocus();
    }

    function countOf(tag) {
        return all.filter(item => !tag || item.tag === tag).length;
    }

    function statusColor(status) {
        const palette = root.shell.palette;
        return {
            draft: palette.wood,
            running: palette.sky,
            done: palette.leaf,
            failed: palette.rose,
            cancelled: palette.off
        }[status];
    }

    // A tag that is no longer configured is off.
    function tagColor(name) {
        const tag = tags.find(tag => tag.name === name);
        return root.shell.palette[tag ? tag.color : "off"];
    }

    FileView {
        path: root.stateDir + "/index.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.all = JSON.parse(text());
            if (!root.selectedId && root.all.length)
                root.selectedId = root.all[0].id;
        }
    }

    FileView {
        path: root.stateDir + "/projects.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.projects = JSON.parse(text())
    }

    FileView {
        path: root.stateDir + "/settings.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const settings = JSON.parse(text());
            root.model = settings.model;
            root.effort = settings.effort;
            root.tags = settings.tags || [];
        }
    }

    Process {
        id: cli
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.error = String(text || "").trim()
        }
        onExited: Qt.callLater(root.next)
    }

    // Title, filters, model and the new button. Above the body, which the open lists overlap.
    Item {
        z: 5
        width: parent.width
        height: 30

        Text {
            id: title
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 18
            text: "Incident investigator"
        }

        Row {
            anchors.left: title.right
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: root.tags.length ? [["", "All"]].concat(root.tags.map(tag => [tag.name, tag.name])) : []

                delegate: Rectangle {
                    id: chip

                    required property var modelData
                    readonly property bool on: root.tagFilter === modelData[0]

                    width: chipLabel.implicitWidth + 20
                    height: 24
                    radius: 12
                    color: on || chipMouse.containsMouse || activeFocus ? root.shell.palette.sel : "transparent"
                    border.color: on ? root.tagColor(modelData[0]) : root.shell.palette.dim
                    border.width: 1
                    activeFocusOnTab: true

                    Keys.onReturnPressed: root.tagFilter = modelData[0]
                    Keys.onSpacePressed: root.tagFilter = modelData[0]

                    Text {
                        id: chipLabel
                        anchors.centerIn: parent
                        color: chip.on ? root.shell.palette.fg : root.shell.palette.off
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 12
                        text: chip.modelData[1] + " " + root.countOf(chip.modelData[0])
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.tagFilter = chip.modelData[0]
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Select {
                options: Format.models
                value: root.model
                onPicked: option => root.run(["settings", "-model=" + option])
            }

            Select {
                options: Format.efforts
                value: root.effort
                onPicked: option => root.run(["settings", "-effort=" + option])
            }

            Meta {
                visible: root.confirmingClear
                anchors.verticalCenter: parent.verticalCenter
                text: "Clear " + root.clearable.length + "?"
            }

            Btn {
                visible: root.confirmingClear
                label: "Yes"
                danger: true
                onClicked: root.clearListed()
            }
            Btn {
                visible: root.confirmingClear
                label: "No"
                onClicked: root.confirmingClear = false
            }

            Btn {
                visible: !root.confirmingClear && root.clearable.length > 0
                icon: Format.icons.trash
                label: root.clearLabel
                danger: true
                onClicked: root.confirmingClear = true
            }

            Btn {
                icon: Format.icons.plus
                label: "New"
                primary: true
                onClicked: root.draft()
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 1
        color: root.shell.palette.dim
    }

    Text {
        visible: root.error !== ""
        width: parent.width
        wrapMode: Text.WordWrap
        color: root.shell.palette.rose
        font.family: Ui.Fonts.mono
        font.pixelSize: 12
        text: root.error
    }

    Item {
        id: body
        width: parent.width
        height: parent.height - y

        // Narrows the list; the open project list overlaps it.
        Column {
            id: listFilters
            z: 1
            anchors.left: parent.left
            anchors.top: parent.top
            width: root.listWidth
            spacing: 6

            Field {
                placeholder: "Search"
                onTextChanged: root.query = text.trim()
            }

            Rectangle {
                id: projectFilterBox

                property bool open: false

                function toggle(project) {
                    root.projectFilter = !project ? [] : root.projectFilter.includes(project) ? root.projectFilter.filter(other => other !== project) : root.projectFilter.concat([project]);
                }

                function close() {
                    open = false;
                    forceActiveFocus();
                }

                width: parent.width
                height: 28
                radius: 4
                color: projectFilterMouse.containsMouse || activeFocus ? root.shell.palette.sel : "transparent"
                border.color: open ? root.shell.palette.fg : root.shell.palette.dim
                border.width: 1
                activeFocusOnTab: true

                Keys.onReturnPressed: open = !open
                Keys.onSpacePressed: open = !open
                Keys.onEscapePressed: event => {
                    event.accepted = open;
                    open = false;
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: filterChevron.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    color: root.projectFilter.length ? root.shell.palette.fg : root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 12
                    text: root.projectFilter.join(", ") || "All projects"
                }

                Text {
                    id: filterChevron
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 13
                    text: Format.icons.chevron
                }

                MouseArea {
                    id: projectFilterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: projectFilterBox.open = !projectFilterBox.open
                }

                Rectangle {
                    visible: projectFilterBox.open
                    anchors.top: parent.bottom
                    anchors.topMargin: 2
                    width: parent.width
                    height: filterOptions.implicitHeight + 8
                    radius: 4
                    color: root.shell.palette.bg
                    border.color: root.shell.palette.fg
                    border.width: 1

                    Column {
                        id: filterOptions
                        anchors.fill: parent
                        anchors.margins: 4

                        Repeater {
                            model: [""].concat(root.listedProjects)

                            delegate: Rectangle {
                                id: filterOption

                                required property string modelData

                                width: parent.width
                                height: 24
                                radius: 3
                                color: filterOptionMouse.containsMouse || activeFocus ? root.shell.palette.sel : "transparent"
                                activeFocusOnTab: true

                                Keys.onReturnPressed: projectFilterBox.toggle(modelData)
                                Keys.onSpacePressed: projectFilterBox.toggle(modelData)
                                Keys.onEscapePressed: projectFilterBox.close()

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 6
                                    anchors.right: parent.right
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    color: filterOption.modelData ? (root.projectFilter.includes(filterOption.modelData) ? root.shell.palette.fg : root.shell.palette.off) : (root.projectFilter.length ? root.shell.palette.off : root.shell.palette.fg)
                                    font.family: Ui.Fonts.mono
                                    font.pixelSize: 12
                                    text: (root.projectFilter.includes(filterOption.modelData) ? Format.icons.done + " " : "") + (filterOption.modelData || "All projects")
                                }

                                MouseArea {
                                    id: filterOptionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: projectFilterBox.toggle(filterOption.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        ListView {
            id: list
            anchors.left: parent.left
            anchors.top: listFilters.bottom
            anchors.topMargin: 8
            anchors.bottom: listBar.visible ? listBar.top : parent.bottom
            anchors.bottomMargin: listBar.visible ? 8 : 0
            width: root.listWidth
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: root.items

            delegate: ItemRow {}

            Text {
                visible: list.count === 0
                anchors.centerIn: parent
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: "No investigations"
            }
        }

        // Asks to confirm a delete.
        Rectangle {
            id: listBar
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: root.listWidth
            height: barColumn.implicitHeight + 16
            visible: root.confirmingDelete.length > 0
            radius: 4
            color: "transparent"
            border.color: activeFocus ? root.shell.palette.rose : root.shell.palette.dim
            border.width: 1

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Y)
                    root.answerDelete(true);
                else if (event.key === Qt.Key_Escape || event.key === Qt.Key_N || event.key === Qt.Key_Backspace)
                    root.answerDelete(false);
                else
                    return;
                event.accepted = true;
            }

            Column {
                id: barColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 8
                spacing: 6

                Meta {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: root.shell.palette.fg
                    text: "Delete " + root.confirmingDelete.length + (root.confirmingDelete.length === 1 ? " investigation?" : " investigations?")
                }

                Row {
                    spacing: 8

                    Btn {
                        label: "Yes"
                        danger: true
                        onClicked: root.answerDelete(true)
                    }
                    Btn {
                        label: "No"
                        onClicked: root.answerDelete(false)
                    }
                    Meta {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "y / n"
                    }
                }
            }
        }

        Rectangle {
            id: divider
            anchors.left: list.right
            anchors.leftMargin: 8
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: root.shell.palette.dim

            MouseArea {
                anchors.fill: parent
                anchors.leftMargin: -4
                anchors.rightMargin: -4
                cursorShape: Qt.SplitHCursor
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    const x = mapToItem(body, mouse.x, 0).x - divider.anchors.leftMargin;
                    root.listWidth = Math.max(140, Math.min(x, body.width - 240));
                }
            }
        }

        Item {
            anchors.left: divider.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // A new model array rebuilds the view, so a view never carries over the
            // scroll position or typed text of the previous selection.
            Repeater {
                id: formView
                model: root.formId ? [root.formId] : []

                delegate: Form {
                    required property string modelData

                    visible: root.pickedItems.length < 2
                    width: parent.width
                    height: parent.height
                    itemId: modelData
                    item: root.shown
                }
            }

            Repeater {
                id: detailView
                model: root.detailId ? [root.detailId] : []

                delegate: Detail {
                    visible: root.pickedItems.length < 2
                    width: parent.width
                    height: parent.height
                    item: root.shown
                }
            }

            Column {
                id: multi

                property bool confirming: false

                visible: root.pickedItems.length >= 2
                width: parent.width
                spacing: 8
                onVisibleChanged: confirming = false

                Text {
                    color: root.shell.palette.fg
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 15
                    font.bold: true
                    text: root.pickedItems.length + " investigations selected"
                }

                Repeater {
                    model: root.pickedItems

                    delegate: Meta {
                        required property var modelData

                        width: parent.width
                        elide: Text.ElideRight
                        text: Format.name(modelData) + "  ·  " + modelData.projects.join(", ")
                    }
                }

                Row {
                    spacing: 8

                    Btn {
                        primary: true
                        icon: Format.icons.plus
                        label: "Combine"
                        onClicked: root.combinePicked()
                    }
                    Btn {
                        label: "Clear"
                        onClicked: root.picked = []
                    }
                    Btn {
                        visible: !multi.confirming && root.deletable.length > 0
                        icon: Format.icons.trash
                        label: "Delete " + root.deletable.length
                        danger: true
                        onClicked: multi.confirming = true
                    }
                    Meta {
                        visible: multi.confirming
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Delete " + root.deletable.length + "?"
                    }
                    Btn {
                        visible: multi.confirming
                        label: "Yes"
                        danger: true
                        onClicked: root.deletePicked()
                    }
                    Btn {
                        visible: multi.confirming
                        label: "No"
                        onClicked: multi.confirming = false
                    }
                }
            }

            Text {
                visible: root.current === null
                anchors.centerIn: parent
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: "Select an investigation"
            }
        }
    }

    component Btn: Rectangle {
        id: btn

        property string icon: ""
        property string label: ""
        property bool primary: false
        property bool danger: false
        signal clicked

        width: btnRow.implicitWidth + 20
        height: 26
        radius: 4
        color: activeFocus || btnMouse.containsMouse ? root.shell.palette.sel : "transparent"
        border.color: primary ? root.shell.palette.fg : danger ? root.shell.palette.rose : root.shell.palette.dim
        border.width: 1
        activeFocusOnTab: true

        Keys.onReturnPressed: btn.clicked()
        Keys.onSpacePressed: btn.clicked()

        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                visible: btn.icon !== ""
                color: btn.danger ? root.shell.palette.rose : root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: btn.icon
            }

            Text {
                color: btn.danger ? root.shell.palette.rose : root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 12
                text: btn.label
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }

    // A small icon that acts on one message.
    component IconBtn: Text {
        signal clicked

        activeFocusOnTab: true
        color: iconMouse.containsMouse || activeFocus ? root.shell.palette.fg : root.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 13

        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()

        MouseArea {
            id: iconMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    // Read-only text that a drag selects; a right-click in the conversation offers to copy the selection.
    component Selectable: TextEdit {
        id: edit

        readOnly: true
        selectByMouse: true
        persistentSelection: true
        selectionColor: root.shell.palette.dim
        selectedTextColor: root.shell.palette.fg

        onLinkActivated: link => {
            if (link.startsWith("https://"))
                Quickshell.execDetached(["xdg-open", link]);
        }
        onActiveFocusChanged: if (!activeFocus && root.menuEdit === edit)
            root.menuEdit = null
        onSelectedTextChanged: {
            if (selectedText) {
                if (root.selection && root.selection !== edit)
                    root.selection.deselect();
                root.selection = edit;
            } else if (root.selection === edit) {
                root.selection = null;
            }
            if (root.menuEdit === edit)
                root.menuEdit = null;
        }
        Keys.onEscapePressed: event => {
            event.accepted = root.menuEdit === edit;
            if (event.accepted)
                root.menuEdit = null;
        }
    }

    // A dropdown of strings; the open list overlaps what is below.
    component Select: Rectangle {
        id: select

        property var options: []
        property string value: ""
        property bool open: false
        signal picked(string option)

        function choose(option) {
            open = false;
            picked(option);
        }

        width: selectText.implicitWidth + selectChevron.implicitWidth + 28
        height: 26
        radius: 4
        color: selectMouse.containsMouse || activeFocus ? root.shell.palette.sel : "transparent"
        border.color: open ? root.shell.palette.fg : root.shell.palette.dim
        border.width: 1
        activeFocusOnTab: true

        Keys.onReturnPressed: open = !open
        Keys.onSpacePressed: open = !open
        Keys.onEscapePressed: event => {
            event.accepted = open;
            open = false;
        }

        Text {
            id: selectText
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 12
            text: select.value
        }

        Text {
            id: selectChevron
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 13
            text: Format.icons.chevron
        }

        MouseArea {
            id: selectMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: select.open = !select.open
        }

        Rectangle {
            visible: select.open
            anchors.top: parent.bottom
            anchors.topMargin: 2
            anchors.right: parent.right
            width: selectOptions.implicitWidth + 8
            height: selectOptions.implicitHeight + 8
            radius: 4
            color: root.shell.palette.bg
            border.color: root.shell.palette.fg
            border.width: 1

            Column {
                id: selectOptions
                x: 4
                y: 4

                Repeater {
                    model: select.options

                    delegate: Rectangle {
                        id: option

                        required property string modelData

                        width: Math.max(optionText.implicitWidth + 12, select.width - 8)
                        height: 24
                        radius: 3
                        color: optionMouse.containsMouse || activeFocus ? root.shell.palette.sel : "transparent"
                        activeFocusOnTab: true

                        Keys.onReturnPressed: select.choose(modelData)
                        Keys.onSpacePressed: select.choose(modelData)
                        Keys.onEscapePressed: {
                            select.open = false;
                            select.forceActiveFocus();
                        }

                        Text {
                            id: optionText
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            color: option.modelData === select.value ? root.shell.palette.fg : root.shell.palette.off
                            font.family: Ui.Fonts.mono
                            font.pixelSize: 12
                            text: (option.modelData === select.value ? Format.icons.done + " " : "") + option.modelData
                        }

                        MouseArea {
                            id: optionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: select.choose(option.modelData)
                        }
                    }
                }
            }
        }
    }

    component Badge: Rectangle {
        id: badge

        property string tag: ""

        visible: tag !== ""
        width: badgeText.implicitWidth + 12
        height: 16
        radius: 3
        color: root.tagColor(tag)

        Text {
            id: badgeText
            anchors.centerIn: parent
            color: root.shell.palette.bg
            font.family: Ui.Fonts.mono
            font.pixelSize: 10
            font.bold: true
            text: badge.tag.toUpperCase()
        }
    }

    component ItemRow: Rectangle {
        id: row

        required property var modelData
        required property int index
        readonly property bool selected: root.selectedId === modelData.id || root.picked.indexOf(modelData.id) >= 0

        // The project and the age on separate lines when they do not fit on one.
        readonly property string subtitle: (modelData.projects.join(", ") || "no project") + "  ·  " + Format.ago(modelData.createdAt) + (modelData.alert ? "  ·  " + Format.icons.alert : "")
        readonly property bool stacked: subtitleMetrics.width > width - 44

        width: ListView.view.width
        height: stacked ? 66 : 52
        radius: 4
        color: selected ? root.shell.palette.sel : "transparent"
        // Focus and hover do not fill, so only the shown investigation looks selected.
        border.color: activeFocus || rowMouse.containsMouse ? root.shell.palette.dim : "transparent"
        border.width: 1
        activeFocusOnTab: true

        onActiveFocusChanged: if (activeFocus)
            ListView.view.currentIndex = index

        Keys.onReturnPressed: {
            root.picked = [];
            root.selectedId = modelData.id;
        }
        Keys.onSpacePressed: root.togglePick(modelData.id)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_J || event.key === Qt.Key_Down)
                root.step(1);
            else if (event.key === Qt.Key_K || event.key === Qt.Key_Up)
                root.step(-1);
            else if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete)
                root.askDelete(modelData.id);
            else if (event.key === Qt.Key_Escape && root.picked.length)
                root.picked = [];
            else
                return;
            event.accepted = true;
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mouse => root.click(row.index, mouse.modifiers)
        }

        Text {
            id: statusIcon
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            color: root.statusColor(row.modelData.status)
            font.family: Ui.Fonts.mono
            font.pixelSize: 16
            text: Format.icons[row.modelData.status]
        }

        Badge {
            id: rowBadge
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 10
            tag: row.modelData.tag
        }

        Text {
            anchors.left: statusIcon.right
            anchors.leftMargin: 8
            anchors.right: rowBadge.left
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 8
            elide: Text.ElideRight
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 13
            font.bold: true
            text: Format.name(row.modelData)
        }

        TextMetrics {
            id: subtitleMetrics
            font.family: Ui.Fonts.mono
            font.pixelSize: 11
            text: row.subtitle
        }

        Column {
            anchors.left: statusIcon.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 11
                text: row.stacked ? (row.modelData.projects.join(", ") || "no project") : row.subtitle
            }

            Text {
                visible: row.stacked
                width: parent.width
                elide: Text.ElideRight
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 11
                text: Format.ago(row.modelData.createdAt) + (row.modelData.alert ? "  ·  " + Format.icons.alert : "")
            }
        }
    }

    component Meta: Text {
        color: root.shell.palette.off
        font.family: Ui.Fonts.mono
        font.pixelSize: 12
    }

    component Alert: Rectangle {
        property var alert

        visible: alert !== null && alert !== undefined
        width: parent ? parent.width : 0
        height: visible ? alertColumn.implicitHeight + 16 : 0
        radius: 4
        color: "transparent"
        border.color: root.shell.palette.dim
        border.width: 1

        Column {
            id: alertColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 11
                text: Format.icons.alert + "  " + (alert ? alert.app + "  ·  " + alert.summary : "")
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 12
                text: alert ? alert.body : ""
            }
        }
    }

    component Field: Rectangle {
        id: field

        property alias text: input.text
        property alias placeholder: hint.text
        property bool multiline: false
        property alias readOnly: input.readOnly

        signal submitted

        function focusInput() {
            input.forceActiveFocus();
        }

        width: parent ? parent.width : 0
        height: multiline ? 84 : 28
        radius: 4
        color: "transparent"
        border.color: input.activeFocus ? root.shell.palette.fg : root.shell.palette.dim
        border.width: 1

        Text {
            id: hint
            visible: input.text === ""
            anchors.fill: input
            color: root.shell.palette.off
            font.family: Ui.Fonts.mono
            font.pixelSize: 13
        }

        TextEdit {
            id: input
            anchors.fill: parent
            anchors.margins: 6
            color: root.shell.palette.fg
            selectionColor: root.shell.palette.sel
            selectedTextColor: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 13
            wrapMode: field.multiline ? TextEdit.Wrap : TextEdit.NoWrap
            // A single-line field takes Enter as submit, never a newline.
            Keys.onReturnPressed: event => {
                if (field.multiline)
                    event.accepted = false;
                else
                    field.submitted();
            }
            clip: true
        }
    }

    // A draft's input, saved as it is typed so it survives switching rows.
    component Form: Column {
        id: form

        required property string itemId
        required property var item
        property var projects: []
        property string tag: ""
        property bool open: false
        // Typing a project that is not in the list yet; base is what was picked before.
        property bool adding: false
        property var base: []
        property bool loaded: false

        function save() {
            saveLater.stop();
            root.run(["edit", itemId, "-projects=" + projects.join(","), "-tag=" + tag, "-trace-id=" + traceField.text, "-notes=" + notesField.text]);
        }

        function changed() {
            if (loaded)
                saveLater.restart();
        }

        function toggle(name) {
            projects = projects.includes(name) ? projects.filter(other => other !== name) : projects.concat([name]);
        }

        function close() {
            open = false;
            projectBox.forceActiveFocus();
        }

        function start() {
            save();
            root.run(["start", itemId]);
        }

        function discard() {
            saveLater.stop();
            root.remove(itemId);
        }

        function addProject() {
            open = false;
            adding = true;
            base = projects;
            projectField.text = "";
            projectField.focusInput();
        }

        onProjectsChanged: changed()
        onTagChanged: changed()
        // Filled once: a binding would overwrite typing on every reload.
        Component.onCompleted: {
            projects = item.projects.slice();
            tag = item.tag;
            traceField.text = item.traceId;
            notesField.text = item.notes;
            loaded = true;
        }
        Component.onDestruction: if (saveLater.running)
            save()

        Timer {
            id: saveLater
            interval: 500
            onTriggered: form.save()
        }

        spacing: 8

        Row {
            spacing: 10

            Text {
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 16
                font.bold: true
                text: form.item.alert ? "Draft from alert" : "New investigation"
            }

            Badge {
                anchors.verticalCenter: parent.verticalCenter
                tag: form.tag
            }
        }

        Alert {
            alert: form.item.alert
        }

        Meta {
            visible: root.tags.length > 0
            text: "Tag (optional)"
        }

        Row {
            visible: root.tags.length > 0
            spacing: 8

            Repeater {
                model: root.tags

                // Picking the picked one again clears it.
                delegate: Btn {
                    required property var modelData

                    label: modelData.name
                    primary: form.tag === modelData.name
                    onClicked: form.tag = form.tag === modelData.name ? "" : modelData.name
                }
            }
        }

        Meta {
            text: "GCP project"
        }

        Field {
            id: projectField
            visible: form.adding
            placeholder: "my-project"
            onTextChanged: if (form.adding)
                form.projects = form.base.concat(text.trim() && !form.base.includes(text.trim()) ? [text.trim()] : [])
            onSubmitted: form.adding = false
        }

        Rectangle {
            id: projectBox
            visible: !form.adding
            // Above the fields below, which the open list overlaps.
            z: form.open ? 10 : 0
            width: parent.width
            height: 28
            radius: 4
            color: projectMouse.containsMouse || activeFocus ? root.shell.palette.sel : "transparent"
            border.color: form.open ? root.shell.palette.fg : root.shell.palette.dim
            border.width: 1
            activeFocusOnTab: true

            Keys.onReturnPressed: form.open = !form.open
            Keys.onSpacePressed: form.open = !form.open
            Keys.onEscapePressed: event => {
                event.accepted = form.open;
                form.open = false;
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: projectChevron.left
                anchors.rightMargin: 4
                elide: Text.ElideRight
                color: form.projects.length ? root.shell.palette.fg : root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: form.projects.join(", ") || "Select projects"
            }

            Text {
                id: projectChevron
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 13
                text: Format.icons.chevron
            }

            MouseArea {
                id: projectMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: form.open = !form.open
            }

            Rectangle {
                visible: form.open
                anchors.top: parent.bottom
                anchors.topMargin: 2
                width: parent.width
                height: projectList.implicitHeight + 8
                radius: 4
                color: root.shell.palette.bg
                border.color: root.shell.palette.fg
                border.width: 1

                Column {
                    id: projectList
                    anchors.fill: parent
                    anchors.margins: 4

                    Repeater {
                        model: [...new Set(root.projects.concat(form.projects))]

                        delegate: Rectangle {
                            id: option

                            required property string modelData

                            width: parent.width
                            height: 24
                            radius: 3
                            color: optionMouse.containsMouse || activeFocus ? root.shell.palette.sel : "transparent"
                            activeFocusOnTab: true

                            Keys.onReturnPressed: form.toggle(modelData)
                            Keys.onSpacePressed: form.toggle(modelData)
                            Keys.onEscapePressed: form.close()

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.shell.palette.fg
                                font.family: Ui.Fonts.mono
                                font.pixelSize: 13
                                text: (form.projects.includes(option.modelData) ? Format.icons.done + " " : "") + option.modelData
                            }

                            MouseArea {
                                id: optionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: form.toggle(option.modelData)
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 24
                        radius: 3
                        color: addMouse.containsMouse || activeFocus ? root.shell.palette.sel : "transparent"
                        activeFocusOnTab: true

                        Keys.onReturnPressed: form.addProject()
                        Keys.onSpacePressed: form.addProject()
                        Keys.onEscapePressed: form.close()

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.shell.palette.off
                            font.family: Ui.Fonts.mono
                            font.pixelSize: 13
                            text: Format.icons.plus + "  Add a project…"
                        }

                        MouseArea {
                            id: addMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: form.addProject()
                        }
                    }
                }
            }
        }

        Meta {
            text: "Trace id (optional)"
        }

        Field {
            id: traceField
            placeholder: "4f9d2c1ab7e84d1c9f3a0b5e6c7d8e90"
            onTextChanged: form.changed()
        }

        Meta {
            text: "Notes"
        }

        Field {
            id: notesField
            multiline: true
            placeholder: "Anything Claude should know, e.g. a Logs URL or a recent deploy"
            onTextChanged: form.changed()
        }

        Row {
            spacing: 8

            Btn {
                icon: Format.icons.play
                label: "Run"
                primary: true
                onClicked: form.start()
            }
            Btn {
                label: "Discard"
                onClicked: form.discard()
            }
        }
    }

    // A started investigation: its conversation, up to the answer or while it runs.
    component Detail: Column {
        id: detail

        required property var item
        readonly property bool running: item.status === "running"
        // The last answer is the conclusion; a failed or empty run has none.
        readonly property int answerIndex: item.messages.map(message => message.kind).lastIndexOf("assistant")
        // A follow-up resumes the session; a draft that never ran has none.
        readonly property bool canFollowUp: !running && item.sessionId !== ""
        property bool confirming: false

        function send() {
            if (!canFollowUp || !followField.text.trim())
                return;
            root.run(["followup", item.id, followField.text]);
            followField.text = "";
        }

        function followUp() {
            followField.focusInput();
        }

        spacing: 8

        Row {
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: root.statusColor(detail.item.status)
                font.family: Ui.Fonts.mono
                font.pixelSize: 18
                text: Format.icons[detail.item.status]
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 15
                font.bold: true
                text: Format.name(detail.item)
            }

            Badge {
                anchors.verticalCenter: parent.verticalCenter
                tag: detail.item.tag
            }

            // The Claude Code profile, so a run on the wrong account shows.
            Meta {
                visible: !!detail.item.claudeConfigDir
                anchors.verticalCenter: parent.verticalCenter
                text: "profile " + String(detail.item.claudeConfigDir).replace(Quickshell.env("HOME"), "~")
            }

            // What the run used, so one on the wrong model shows.
            Meta {
                visible: !!detail.item.model
                anchors.verticalCenter: parent.verticalCenter
                text: detail.item.model + "  ·  " + detail.item.effort
            }
        }

        Meta {
            width: parent.width
            elide: Text.ElideRight
            text: detail.item.status + "  ·  " + detail.item.projects.join(", ") + "  ·  started " + Format.ago(detail.item.startedAt) + (detail.item.finishedAt ? "  ·  took " + Format.duration(detail.item.finishedAt - detail.item.startedAt) : "") + "  ·  $" + detail.item.costUsd.toFixed(2)
        }

        Row {
            visible: root.tags.length > 0
            spacing: 8

            Repeater {
                model: root.tags

                // Picking the picked one again clears it.
                delegate: Btn {
                    required property var modelData

                    label: modelData.name
                    primary: detail.item.tag === modelData.name
                    onClicked: root.run(["tag", detail.item.id].concat(detail.item.tag === modelData.name ? [] : [modelData.name]))
                }
            }
        }

        Row {
            spacing: 8

            Btn {
                visible: detail.running
                icon: Format.icons.stop
                label: "Cancel"
                danger: true
                onClicked: root.run(["cancel", detail.item.id])
            }
            Btn {
                visible: !detail.running
                icon: Format.icons.refresh
                label: "Re-run"
                onClicked: root.run(["start", detail.item.id])
            }
            Btn {
                visible: detail.item.status === "done"
                icon: Format.icons.reply
                label: "Follow up"
                onClicked: detail.followUp()
            }
            Btn {
                visible: detail.item.sessionId !== "" && !!detail.item.claudeConfigDir
                icon: Format.icons.terminal
                label: "Terminal"
                onClicked: root.terminal(detail.item)
            }
            Btn {
                visible: !detail.running && detail.answerIndex >= 0
                icon: Format.icons.copy
                label: "Copy"
                onClicked: root.copy(detail.item.messages[detail.answerIndex].text)
            }
            Btn {
                visible: !detail.running && !detail.confirming
                icon: Format.icons.trash
                label: "Delete"
                danger: true
                onClicked: detail.confirming = true
            }

            Meta {
                visible: detail.confirming
                anchors.verticalCenter: parent.verticalCenter
                text: "Delete?"
            }
            Btn {
                visible: detail.confirming
                label: "Yes"
                danger: true
                onClicked: root.remove(detail.item.id)
            }
            Btn {
                visible: detail.confirming
                label: "No"
                onClicked: detail.confirming = false
            }
        }

        Alert {
            alert: detail.item.alert
        }

        // The user and organization ids the tool output named; a name column joins them once they can be resolved.
        Column {
            id: entities

            readonly property var found: detail.item.entities || []
            readonly property int users: found.filter(entity => entity.kind === "user").length
            property bool expanded: false

            visible: found.length > 0
            width: parent.width
            spacing: 2

            Text {
                activeFocusOnTab: true
                Keys.onReturnPressed: entities.expanded = !entities.expanded
                Keys.onSpacePressed: entities.expanded = !entities.expanded
                color: entitiesMouse.containsMouse || activeFocus ? root.shell.palette.fg : root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 12
                text: entities.users + (entities.users === 1 ? " user" : " users") + "  ·  " + (entities.found.length - entities.users) + (entities.found.length - entities.users === 1 ? " organization" : " organizations") + "  " + (entities.expanded ? "▾" : "▸")

                MouseArea {
                    id: entitiesMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: entities.expanded = !entities.expanded
                }
            }

            Repeater {
                model: entities.expanded ? entities.found : []

                delegate: Row {
                    required property var modelData

                    spacing: 8

                    Meta {
                        width: 90
                        text: modelData.kind
                    }
                    Text {
                        color: root.shell.palette.water
                        font.family: Ui.Fonts.mono
                        font.pixelSize: 12
                        text: modelData.id
                    }
                    Meta {
                        text: "×" + modelData.count
                    }
                    IconBtn {
                        text: Format.icons.copy
                        onClicked: root.copy(modelData.id)
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: root.shell.palette.dim
        }

        Flickable {
            id: scroller
            width: parent.width
            height: parent.height - y - followUp.height - parent.spacing
            contentWidth: width
            contentHeight: conversation.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // Sticks to the newest message until the user scrolls away from the end.
            property bool follow: true
            function toEnd() {
                contentY = Math.max(0, contentHeight - height);
            }
            onContentHeightChanged: if (follow) {
                toEnd();
                settle.restart();
            }
            onMovementEnded: follow = atYEnd

            Rectangle {
                id: copyMenu

                readonly property point at: scroller.contentItem.mapFromItem(null, root.menuAt.x, root.menuAt.y)

                visible: root.menuEdit !== null
                z: 10
                x: Math.min(at.x, conversation.width - width)
                y: at.y
                width: 64
                height: 26
                radius: 4
                color: root.shell.palette.bg
                border.color: root.shell.palette.fg
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    color: copyMouse.containsMouse ? root.shell.palette.fg : root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 12
                    text: Format.icons.copy + "  Copy"
                }

                MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.copy(root.menuEdit.selectedText);
                        root.menuEdit = null;
                    }
                }
            }

            // A drag ends wherever the pointer is, so a right-click anywhere in the conversation copies the selection.
            MouseArea {
                z: 5
                width: conversation.width
                height: Math.max(conversation.height, scroller.height)
                acceptedButtons: Qt.RightButton
                onPressed: mouse => {
                    if (!root.selection)
                        return;
                    root.selection.forceActiveFocus();
                    root.menuAt = mapToItem(null, mouse.x, mouse.y);
                    root.menuEdit = root.selection;
                }
            }

            // Markdown text lays out after the first pass, so wait for the heights to stop moving.
            Timer {
                id: settle
                interval: 50
                onTriggered: if (scroller.follow)
                    scroller.toEnd()
            }

            Column {
                id: conversation
                width: scroller.width
                spacing: 10

                Repeater {
                    id: messages
                    model: detail.item.messages

                    delegate: Loader {
                        id: message

                        required property var modelData
                        required property int index

                        width: conversation.width
                        sourceComponent: modelData.kind === "user" ? userMessage : modelData.kind === "tools" ? toolMessage : assistantMessage

                        // What you sent, on the right.
                        Component {
                            id: userMessage

                            Item {
                                id: userItem

                                property bool editing: false

                                height: editing ? editor.height : bubble.height

                                Text {
                                    id: measure
                                    visible: false
                                    font.family: Ui.Fonts.mono
                                    font.pixelSize: 13
                                    textFormat: Text.MarkdownText
                                    text: Format.literals(message.modelData.text, root.shell.palette.water)
                                }

                                Rectangle {
                                    id: bubble
                                    visible: !userItem.editing
                                    anchors.right: parent.right
                                    width: Math.min(parent.width * 0.8, measure.implicitWidth + 24)
                                    height: bubbleText.implicitHeight + 16
                                    radius: 8
                                    color: root.shell.palette.sel

                                    Selectable {
                                        id: bubbleText
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        wrapMode: TextEdit.WordWrap
                                        textFormat: TextEdit.MarkdownText
                                        color: root.shell.palette.fg
                                        font.family: Ui.Fonts.mono
                                        font.pixelSize: 13
                                        text: Format.literals(message.modelData.text, root.shell.palette.water)
                                    }
                                }

                                // Branches the investigation from this message; the original is kept.
                                IconBtn {
                                    visible: !userItem.editing && !detail.running && detail.item.sessionId !== ""
                                    anchors.right: bubble.left
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: bubble.verticalCenter
                                    text: Format.icons.draft
                                    onClicked: {
                                        editField.text = message.modelData.text;
                                        userItem.editing = true;
                                        editField.focusInput();
                                    }
                                }

                                Column {
                                    id: editor
                                    visible: userItem.editing
                                    width: parent.width
                                    spacing: 6

                                    Field {
                                        id: editField
                                        multiline: true
                                    }

                                    Row {
                                        spacing: 8

                                        Btn {
                                            primary: true
                                            icon: Format.icons.play
                                            label: "Branch"
                                            onClicked: {
                                                root.run(["branch", detail.item.id, String(message.index), editField.text]);
                                                userItem.editing = false;
                                            }
                                        }
                                        Btn {
                                            label: "Cancel"
                                            onClicked: userItem.editing = false
                                        }
                                    }
                                }
                            }
                        }

                        // What Claude said, its headings in the accent colour.
                        Component {
                            id: assistantMessage

                            Column {
                                spacing: 6

                                Repeater {
                                    model: Format.blocks(message.modelData.text)

                                    delegate: Selectable {
                                        required property var modelData
                                        readonly property bool plain: modelData.heading || modelData.code

                                        width: parent.width
                                        wrapMode: modelData.code ? TextEdit.Wrap : TextEdit.WordWrap
                                        textFormat: plain ? TextEdit.PlainText : TextEdit.MarkdownText
                                        color: modelData.heading ? root.shell.palette.blossom : modelData.code ? root.shell.palette.water : root.shell.palette.fg
                                        font.family: Ui.Fonts.mono
                                        font.pixelSize: 13
                                        font.bold: modelData.heading
                                        topPadding: modelData.heading ? 6 : 0
                                        text: plain ? modelData.text : Format.literals(modelData.text, root.shell.palette.water)
                                    }
                                }

                                IconBtn {
                                    text: Format.icons.copy
                                    onClicked: root.copy(message.modelData.text)
                                }
                            }
                        }

                        // The commands Claude ran, folded away once it has finished.
                        Component {
                            id: toolMessage

                            Column {
                                id: tools

                                property bool expanded: detail.running
                                readonly property var commands: message.modelData.commands

                                spacing: 2

                                Text {
                                    activeFocusOnTab: true
                                    Keys.onReturnPressed: tools.expanded = !tools.expanded
                                    Keys.onSpacePressed: tools.expanded = !tools.expanded
                                    color: toolMouse.containsMouse || activeFocus ? root.shell.palette.fg : root.shell.palette.off
                                    font.family: Ui.Fonts.mono
                                    font.pixelSize: 12
                                    text: Format.icons.terminal + "  " + tools.commands.length + (tools.commands.length === 1 ? " command" : " commands") + "  " + (tools.expanded ? "▾" : "▸")

                                    MouseArea {
                                        id: toolMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: tools.expanded = !tools.expanded
                                    }
                                }

                                Repeater {
                                    model: tools.expanded ? tools.commands : []

                                    delegate: Selectable {
                                        required property string modelData

                                        width: tools.width
                                        leftPadding: 18
                                        wrapMode: TextEdit.WrapAnywhere
                                        color: root.shell.palette.off
                                        font.family: Ui.Fonts.mono
                                        font.pixelSize: 11
                                        text: "$ " + modelData
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: detail.item.status === "failed"
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: root.shell.palette.rose
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 13
                    text: detail.item.error
                }

                Text {
                    visible: detail.item.status === "cancelled"
                    width: parent.width
                    color: root.shell.palette.off
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 12
                    text: Format.icons.cancelled + "  Cancelled"
                }

                Text {
                    visible: detail.running
                    color: root.shell.palette.sky
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 12
                    text: Format.icons.running + "  working…"
                }
            }
        }

        Row {
            id: followUp
            width: parent.width
            spacing: 8

            Field {
                id: followField
                width: parent.width - 80
                readOnly: !detail.canFollowUp
                placeholder: detail.running ? "Claude is working…" : "Ask a follow-up…"
                onSubmitted: detail.send()
            }

            Btn {
                icon: Format.icons.send
                label: "Send"
                enabled: detail.canFollowUp
                opacity: enabled ? 1 : 0.4
                onClicked: detail.send()
            }
        }
    }
}
