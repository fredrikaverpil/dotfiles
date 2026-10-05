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
    // A context menu: rows returns its tree, at is the rect it hangs from, in
    // window coordinates; a keyboard-opened one selects its first row.
    signal menuRequested(var rows, rect at, bool selectFirst)

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
    // Every investigation's count by tag, "" for all, for the filter.
    readonly property var tagCounts: all.reduce((counts, item) => {
        if (item.tag)
            counts[item.tag] = (counts[item.tag] || 0) + 1;
        return counts;
    }, {
        "": all.length
    })
    readonly property var items: all.filter(item => (!tagFilter || item.tag === tagFilter) && (!projectFilter.length || item.projects.some(project => projectFilter.includes(project))) && Format.matches(item, query))
    readonly property var current: items.find(item => item.id === selectedId) || null
    // What the selected investigation was combined from, which the list marks.
    readonly property var sourceIds: current && current.combined ? current.combined : []

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
    // The list is one Tab stop: the focused row while it has focus, else the selected one.
    readonly property int tabRow: list.activeFocus ? list.currentIndex : Math.max(0, items.findIndex(item => item.id === selectedId))

    // A plain click selects, shift extends from the selection to index, ctrl toggles.
    function click(index, modifiers) {
        const id = items[index].id;
        if (modifiers & Qt.ShiftModifier) {
            pickRange(index);
        } else if (modifiers & Qt.ControlModifier) {
            const base = picked.length ? picked : [selectedId];
            picked = base.indexOf(id) >= 0 ? base.filter(other => other !== id) : base.concat([id]);
        } else {
            picked = [];
            selectedId = id;
        }
    }

    // Picks the rows from the selection to index.
    function pickRange(index) {
        const from = Math.max(0, items.findIndex(item => item.id === selectedId));
        picked = items.slice(Math.min(from, index), Math.max(from, index) + 1).map(item => item.id);
    }

    // Enter on a row: selects it and moves focus into its draft or conversation.
    function open(id) {
        picked = [];
        selectedId = id;
        if (formView.count)
            formView.itemAt(0).focusNotes();
        else if (detailView.count)
            detailView.itemAt(0).followUp();
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

    // Asks to delete the investigations; running ones stay.
    function askDelete(ids) {
        const gone = ids.filter(id => items.some(item => item.id === id && item.status !== "running"));
        if (!gone.length)
            return;
        confirmingDelete = gone;
        listBar.forceActiveFocus();
    }

    function answerDelete(yes) {
        const ids = confirmingDelete;
        confirmingDelete = [];
        if (yes)
            deleteItems(ids);
        Qt.callLater(focusSelected);
    }

    // An inline confirm's keys: y or Enter confirms; n, Esc or Backspace cancels.
    function answerKey(event, answer) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Y)
            answer(true);
        else if (event.key === Qt.Key_Escape || event.key === Qt.Key_N || event.key === Qt.Key_Backspace)
            answer(false);
        else
            return;
        event.accepted = true;
    }

    function combinePicked() {
        run(["combine"].concat(pickedItems.map(item => item.id)));
        picked = [];
    }

    // Running ones stay; cancel them first.
    readonly property var clearable: items.filter(item => item.status !== "running")
    readonly property string clearLabel: projectFilter.length || query ? "Clear listed" : tagFilter ? "Clear " + tagFilter : "Clear all"
    property bool confirmingClear: false
    // Set by the button, the palette and IPC alike.
    onConfirmingClearChanged: if (confirmingClear)
        Qt.callLater(clearBar.forceActiveFocus)

    function answerClear(yes) {
        if (yes)
            clearListed();
        else
            confirmingClear = false;
        Qt.callLater(focusSelected);
    }

    // A draft with the filtered tag, so the filter lists it.
    function draft() {
        run(tagFilter ? ["draft", "-tag=" + tagFilter] : ["draft"]);
    }

    // What the palette's scopes read.
    readonly property var actionState: ({
            all: all,
            listed: items,
            picked: pickedItems,
            clearable: clearable.length,
            clearLabel: clearLabel,
            tags: tags,
            tagCounts: tagCounts,
            model: model,
            effort: effort,
            tagFilter: tagFilter,
            projectFilter: projectFilter,
            projects: listedProjects
        })

    // The window's palette scope.
    function menuScope() {
        return {
            title: "",
            rows: Actions.windowRows(actionState)
        };
    }

    // A row's context menu, looked up by id: a reload rebuilds the delegates.
    function rowMenu(id) {
        const item = items.find(item => item.id === id);
        return item ? Actions.contextRows(actionState, item) : [];
    }

    // A message's context menu, looked up by id: a reload rebuilds the view.
    function messageMenu(id, index) {
        const item = all.find(item => item.id === id);
        return item && item.messages[index] ? Actions.messageRows(item, index, selection ? selection.selectedText : "") : [];
    }

    // Runs a palette row's action on its ids. The shown draft's form and
    // conversation act for their own investigation.
    function runAction(row) {
        const action = row.action;
        const arg = row.arg;
        const id = row.ids.length ? row.ids[0] : "";
        const item = all.find(item => item.id === id);
        const shown = formView.count ? formView.itemAt(0) : null;
        const form = shown && shown.itemId === id ? shown : null;
        const detail = detailView.count && detailId === id ? detailView.itemAt(0) : null;
        if (action === "open")
            open(id);
        else if (action === "run")
            form ? form.start() : run(["start", id]);
        else if (action === "discard")
            form ? form.discard() : remove(id);
        else if (action === "stop")
            run(["cancel", id]);
        else if (action === "rerun")
            run(["start", id]);
        else if (action === "followUp")
            detail ? detail.followUp() : open(id);
        else if (action === "terminal" && item)
            terminal(item);
        else if (action === "copy")
            copy(arg);
        else if (action === "edit" && detail)
            detail.edit(Number(arg));
        else if (action === "branch" && item)
            run(["branch", id, arg, item.messages[Number(arg)].text]);
        else if (action === "tag")
            for (const each of row.ids) {
                if (shown && each === shown.itemId)
                    shown.tag = arg;
                else
                    run(["tag", each].concat(arg ? [arg] : []));
            }
        else if (action === "pick")
            togglePick(id);
        else if (action === "pickAll")
            picked = items.map(item => item.id);
        else if (action === "delete")
            askDelete(row.ids);
        else if (action === "combine")
            combinePicked();
        else if (action === "unpick")
            picked = [];
        else if (action === "search")
            searchField.focusInput();
        else if (action === "select")
            goTo(arg);
        else if (action === "project" && form)
            form.toggle(arg);
        else if (action === "focusTrace" && form)
            form.focusTrace();
        else if (action === "focusNotes" && form)
            form.focusNotes();
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
            toggleProject(arg);
    }

    // Selects an investigation and focuses its row, clearing the filters that hide it.
    function goTo(id) {
        if (!items.some(item => item.id === id)) {
            tagFilter = "";
            projectFilter = [];
            searchField.text = "";
        }
        picked = [];
        selectedId = id;
        focusSelected();
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

    // Focuses the selected row, if the filter lists it, else the content, so keys still land.
    function focusSelected() {
        const index = items.findIndex(item => item.id === selectedId);
        if (index >= 0)
            focusRow(index);
        else
            root.forceActiveFocus();
    }

    // Esc in a text field: unpicks, then leaves the field.
    function leaveField() {
        if (picked.length)
            picked = [];
        else
            focusSelected();
    }

    // Shift with a move: picks from the selection to the next row and focuses it.
    function extend(delta) {
        const index = list.currentIndex + delta;
        if (index < 0 || index >= items.length)
            return;
        pickRange(index);
        focusRow(index);
    }

    // currentIndex first, so the row stays the Tab stop as it takes focus.
    function focusRow(index) {
        list.currentIndex = index;
        list.positionViewAtIndex(index, ListView.Contain);
        const row = list.itemAtIndex(index);
        if (row)
            row.forceActiveFocus();
    }

    // "" lists every project.
    function toggleProject(project) {
        projectFilter = !project ? [] : projectFilter.includes(project) ? projectFilter.filter(other => other !== project) : projectFilter.concat([project]);
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

    // Title, Clear and New. Above the body, which the open lists overlap.
    Item {
        z: 5
        width: parent.width
        height: 30

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 18
            text: "Incident investigator"
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Asks to confirm Clear.
            Row {
                id: clearBar
                visible: root.confirmingClear
                spacing: 8

                Keys.onPressed: event => root.answerKey(event, root.answerClear)

                Meta {
                    anchors.verticalCenter: parent.verticalCenter
                    color: clearBar.activeFocus ? root.shell.palette.fg : root.shell.palette.off
                    text: "Clear " + root.clearable.length + "?"
                }
                Btn {
                    label: "Yes"
                    danger: true
                    onClicked: root.answerClear(true)
                }
                Btn {
                    label: "No"
                    onClicked: root.answerClear(false)
                }
                Meta {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "y / n"
                }
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

        // Narrows the list.
        Column {
            id: listFilters
            anchors.left: parent.left
            anchors.top: parent.top
            width: root.listWidth
            spacing: 6

            function menuScope() {
                return {
                    title: "List",
                    rows: Actions.listRows(root.actionState)
                };
            }

            Field {
                id: searchField
                placeholder: "Search"
                onTextChanged: root.query = text.trim()
            }

            // The filter menu's button, then a chip per active filter; a click clears it.
            Flow {
                id: filterFlow
                visible: root.tags.length > 0 || root.listedProjects.length > 0
                width: parent.width
                spacing: 6

                Btn {
                    id: filterButton
                    icon: Format.icons.filter
                    label: "Filter"
                    onClicked: root.menuRequested(() => Actions.filterRows(root.actionState), filterButton.mapToItem(null, 0, 0, filterButton.width, filterButton.height), filterButton.activeFocus)
                }

                Repeater {
                    model: (root.tagFilter ? [["tag", root.tagFilter]] : []).concat(root.projectFilter.map(project => ["project", project]))

                    delegate: Rectangle {
                        id: chip

                        required property var modelData

                        width: Math.min(chipLabel.implicitWidth, filterFlow.width - 20) + 20
                        height: 26
                        radius: 13
                        color: chipMouse.containsMouse ? root.shell.palette.sel : "transparent"
                        border.color: modelData[0] === "tag" ? root.tagColor(modelData[1]) : root.shell.palette.dim
                        border.width: 1

                        Text {
                            id: chipLabel
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideLeft
                            color: root.shell.palette.fg
                            font.family: Ui.Fonts.mono
                            font.pixelSize: 12
                            text: chip.modelData[1] + " " + Format.icons.close
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: chip.modelData[0] === "tag" ? root.tagFilter = "" : root.toggleProject(chip.modelData[1])
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

            function menuScope() {
                return {
                    title: "List",
                    rows: Actions.listRows(root.actionState)
                };
            }

            delegate: ItemRow {}

            Text {
                visible: list.count === 0
                anchors.centerIn: parent
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
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

            Keys.onPressed: event => root.answerKey(event, root.answerDelete)

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
                visible: root.pickedItems.length >= 2
                width: parent.width
                spacing: 8

                function menuScope() {
                    return {
                        title: root.pickedItems.length + " picked",
                        rows: Actions.pickedRows(root.actionState, false)
                    };
                }

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
                        visible: root.deletable.length > 0
                        icon: Format.icons.trash
                        label: "Delete " + root.deletable.length
                        danger: true
                        onClicked: root.askDelete(root.picked)
                    }
                }
            }

            Text {
                visible: root.current === null
                anchors.centerIn: parent
                color: root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
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
                font.pixelSize: 14
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
        font.pixelSize: 14

        Keys.onReturnPressed: clicked()
        Keys.onSpacePressed: clicked()

        MouseArea {
            id: iconMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    // Read-only text that a drag selects. Its message takes the focus.
    component Selectable: TextEdit {
        id: edit

        readOnly: true
        activeFocusOnPress: false
        selectByMouse: true
        persistentSelection: true
        selectionColor: root.shell.palette.dim
        selectedTextColor: root.shell.palette.fg

        onLinkActivated: link => {
            if (link.startsWith("https://"))
                Quickshell.execDetached(["xdg-open", link]);
        }
        onSelectedTextChanged: {
            if (selectedText) {
                if (root.selection && root.selection !== edit)
                    root.selection.deselect();
                root.selection = edit;
            } else if (root.selection === edit) {
                root.selection = null;
            }
        }
    }

    // Markdown a block at a time: headings at the body's size in the accent
    // colour, code in the body's font.
    component Blocks: Column {
        id: blocks

        property string text: ""

        spacing: 6

        Repeater {
            model: Format.blocks(blocks.text)

            delegate: Selectable {
                required property var modelData
                readonly property bool plain: modelData.heading || modelData.code

                width: blocks.width
                wrapMode: modelData.code ? TextEdit.Wrap : TextEdit.WordWrap
                textFormat: plain ? TextEdit.PlainText : TextEdit.MarkdownText
                color: modelData.heading ? root.shell.palette.blossom : modelData.code ? root.shell.palette.water : root.shell.palette.fg
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                font.bold: modelData.heading
                topPadding: modelData.heading ? 6 : 0
                text: plain ? modelData.text : Format.literals(modelData.text, root.shell.palette.water)
            }
        }
    }

    // A property's value, its name in off while unset. A click, Enter or Space
    // opens its menu on it.
    component Chip: Rectangle {
        id: chip

        property string icon: ""
        property string name: ""
        property string value: ""
        property color accent: root.shell.palette.dim
        // Returns the menu's rows.
        property var rows: () => []

        function popup() {
            root.menuRequested(rows, mapToItem(null, 0, 0, width, height), activeFocus);
        }

        width: chipRow.implicitWidth + 20
        height: 26
        radius: 13
        color: activeFocus || chipMouse.containsMouse ? root.shell.palette.sel : "transparent"
        border.color: activeFocus ? root.shell.palette.fg : accent
        border.width: 1
        activeFocusOnTab: true

        Keys.onReturnPressed: popup()
        Keys.onSpacePressed: popup()

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                color: chipValue.color
                font.family: Ui.Fonts.mono
                font.pixelSize: 14
                text: chip.icon
            }

            Text {
                id: chipValue
                width: Math.min(implicitWidth, 160)
                elide: Text.ElideLeft
                color: chip.value ? root.shell.palette.fg : root.shell.palette.off
                font.family: Ui.Fonts.mono
                font.pixelSize: 12
                text: chip.value || chip.name
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: chip.popup()
        }
    }

    // What the next run starts with.
    component SettingChips: Row {
        spacing: 8

        Chip {
            icon: Format.icons.model
            name: "Model"
            value: root.model
            rows: () => Actions.submenuRows(Actions.windowRows(root.actionState), "model")
        }

        Chip {
            icon: Format.icons.effort
            name: "Effort"
            value: root.effort
            rows: () => Actions.submenuRows(Actions.windowRows(root.actionState), "effort")
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
        readonly property string marks: (modelData.alert ? "  ·  " + Format.icons.alert : "") + (modelData.combined ? "  ·  " + Format.icons.combined : "")

        // The project and the age on separate lines when they do not fit on one.
        readonly property string subtitle: (modelData.projects.join(", ") || "no project") + "  ·  " + Format.ago(modelData.createdAt) + marks
        readonly property bool stacked: subtitleMetrics.width > width - 44

        width: ListView.view.width
        height: stacked ? 66 : 52
        radius: 4
        color: selected ? root.shell.palette.sel : "transparent"
        // Focus and hover do not fill, so only the shown investigation looks selected.
        border.color: activeFocus || rowMouse.containsMouse ? root.shell.palette.dim : "transparent"
        border.width: 1
        activeFocusOnTab: index === root.tabRow

        onActiveFocusChanged: if (activeFocus)
            ListView.view.currentIndex = index

        function menuScope() {
            return {
                title: root.pickedItems.length ? root.pickedItems.length + " picked" : Format.name(modelData),
                rows: Actions.rowRows(root.actionState, modelData)
            };
        }

        Keys.onReturnPressed: root.open(modelData.id)
        Keys.onSpacePressed: root.togglePick(modelData.id)
        Keys.onPressed: event => {
            const range = event.modifiers & Qt.ShiftModifier;
            if (event.key === Qt.Key_J || event.key === Qt.Key_Down)
                range ? root.extend(1) : root.step(1);
            else if (event.key === Qt.Key_K || event.key === Qt.Key_Up)
                range ? root.extend(-1) : root.step(-1);
            else if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete)
                root.askDelete(root.picked.length ? root.picked : [modelData.id]);
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
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                const id = row.modelData.id;
                if (mouse.button === Qt.RightButton)
                    root.menuRequested(() => root.rowMenu(id), mapToItem(null, mouse.x, mouse.y, 0, 0), false);
                else
                    root.click(row.index, mouse.modifiers);
            }
        }

        // A source of the selected combined investigation.
        Rectangle {
            visible: root.sourceIds.indexOf(row.modelData.id) >= 0
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: parent.height - 16
            radius: 1
            color: root.shell.palette.water
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
            font.pixelSize: 14
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
                text: Format.ago(row.modelData.createdAt) + row.marks
            }
        }
    }

    // The investigations a combined one was drafted from, each a button to its
    // row; a deleted one shows its id.
    component Sources: Flow {
        id: sources

        property var ids: []

        visible: ids.length > 0
        width: parent ? parent.width : 0
        spacing: 8

        Meta {
            height: 26
            verticalAlignment: Text.AlignVCenter
            text: Format.icons.combined + "  Combined from"
        }

        Repeater {
            model: sources.ids

            delegate: Loader {
                id: sourceSlot

                required property string modelData
                readonly property var investigation: root.all.find(each => each.id === modelData) || null

                sourceComponent: investigation ? sourceButton : sourceGone

                Component {
                    id: sourceButton

                    Btn {
                        icon: Format.icons[sourceSlot.investigation.status]
                        label: Format.name(sourceSlot.investigation)
                        onClicked: root.goTo(sourceSlot.modelData)
                    }
                }

                Component {
                    id: sourceGone

                    Meta {
                        height: 26
                        verticalAlignment: Text.AlignVCenter
                        text: sourceSlot.modelData + " (deleted)"
                    }
                }
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
        // Whether plain Enter submits; Ctrl+Enter submits any field.
        property bool enterSubmits: !multiline
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
            font.pixelSize: 14
        }

        TextEdit {
            id: input
            anchors.fill: parent
            anchors.margins: 6
            color: root.shell.palette.fg
            selectionColor: root.shell.palette.sel
            selectedTextColor: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 14
            wrapMode: field.multiline ? TextEdit.Wrap : TextEdit.NoWrap
            activeFocusOnTab: true
            // Tab moves focus; a field never takes a tab character.
            Keys.onTabPressed: event => {
                const forward = !(event.modifiers & Qt.ShiftModifier);
                input.nextItemInFocusChain(forward).forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason);
            }
            Keys.onBacktabPressed: input.nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason)
            Keys.onEscapePressed: root.leaveField()
            // A single-line field never takes a newline.
            Keys.onReturnPressed: event => {
                if (field.enterSubmits || event.modifiers & Qt.ControlModifier)
                    field.submitted();
                else
                    event.accepted = !field.multiline;
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
        property bool loaded: false

        function save() {
            saveLater.stop();
            root.run(["edit", itemId, "-projects=" + projects.join(","), "-tag=" + tag, "-trace-id=" + traceField.text, "-notes=" + notesField.text]);
        }

        function focusNotes() {
            notesField.focusInput();
        }

        function focusTrace() {
            traceField.focusInput();
        }

        function menuScope() {
            return {
                title: "Draft",
                rows: Actions.draftRows(root.actionState, {
                    id: itemId,
                    tag: tag,
                    projects: projects,
                    choices: [...new Set(root.projects.concat(projects))],
                    combined: item.combined || []
                })
            };
        }

        function changed() {
            if (loaded)
                saveLater.restart();
        }

        function toggle(name) {
            projects = projects.includes(name) ? projects.filter(other => other !== name) : projects.concat([name]);
        }

        function start() {
            save();
            root.run(["start", itemId]);
        }

        function discard() {
            saveLater.stop();
            root.remove(itemId);
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

        Text {
            color: root.shell.palette.fg
            font.family: Ui.Fonts.mono
            font.pixelSize: 16
            font.bold: true
            text: form.item.alert ? "Draft from alert" : form.item.combined ? "Combined investigation" : "New investigation"
        }

        Alert {
            alert: form.item.alert
        }

        Sources {
            ids: form.item.combined || []
        }

        Meta {
            text: "Trace id (optional)"
        }

        // Enter never starts a paid run; Ctrl+Enter does.
        Field {
            id: traceField
            placeholder: "4f9d2c1ab7e84d1c9f3a0b5e6c7d8e90"
            enterSubmits: false
            onTextChanged: form.changed()
            onSubmitted: form.start()
        }

        Meta {
            text: "Notes"
        }

        Field {
            id: notesField
            multiline: true
            placeholder: "Anything Claude should know, e.g. a Logs URL or a recent deploy"
            onTextChanged: form.changed()
            onSubmitted: form.start()
        }

        // The draft's properties, then its actions.
        Item {
            width: parent.width
            height: 26

            Row {
                spacing: 8

                Chip {
                    visible: root.tags.length > 0
                    icon: Format.icons.tag
                    name: "Tag"
                    value: form.tag
                    accent: form.tag ? root.tagColor(form.tag) : root.shell.palette.dim
                    rows: () => Actions.submenuRows(form.menuScope().rows, "tag")
                }

                Chip {
                    icon: Format.icons.filter
                    name: "Projects"
                    value: form.projects.join(", ")
                    rows: () => Actions.submenuRows(form.menuScope().rows, "projects")
                }

                SettingChips {}
            }

            Row {
                anchors.right: parent.right
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

        function send() {
            if (!canFollowUp || !followField.text.trim())
                return;
            root.run(["followup", item.id, followField.text]);
            followField.text = "";
        }

        function followUp() {
            followField.focusInput();
        }

        // The conversation is one Tab stop: the last focused message, else the newest.
        property int current: -1
        readonly property int tabMessage: current >= 0 && current < messages.count ? current : messages.count - 1
        // Set while a press focuses a message, so the view stays under the pointer.
        property bool pressing: false

        function focusMessage(index) {
            const message = messages.itemAt(index);
            if (message)
                message.forceActiveFocus();
        }

        // The message at a point in the conversation's coordinates, else -1.
        function messageAt(point) {
            const child = conversation.childAt(point.x, point.y);
            for (let index = 0; index < messages.count; index++)
                if (messages.itemAt(index) === child)
                    return index;
            return -1;
        }

        function edit(index) {
            const message = messages.itemAt(index);
            if (message)
                message.edit();
        }

        function menuScope() {
            return {
                title: "Conversation",
                rows: Actions.conversationRows(root.actionState, item, root.selection ? root.selection.selectedText : "")
            };
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

            Chip {
                visible: root.tags.length > 0
                anchors.verticalCenter: parent.verticalCenter
                icon: Format.icons.tag
                name: "Tag"
                value: detail.item.tag
                accent: detail.item.tag ? root.tagColor(detail.item.tag) : root.shell.palette.dim
                rows: () => Actions.submenuRows(detail.menuScope().rows, "tag")
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
                visible: !detail.running
                icon: Format.icons.trash
                label: "Delete"
                danger: true
                onClicked: root.askDelete([detail.item.id])
            }
        }

        Alert {
            alert: detail.item.alert
        }

        Sources {
            ids: detail.item.combined || []
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
            contentHeight: conversation.implicitHeight + 2 * conversation.y
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

            // Scrolls the least that shows item and its outline whole, else to
            // its top. The conversation's inset is the outline's.
            function reveal(item) {
                const top = item.y;
                const bottom = item.y + item.height + 2 * conversation.y;
                if (top < contentY || bottom - top > height)
                    contentY = Math.max(0, top);
                else if (bottom > contentY + height)
                    contentY = bottom - height;
                follow = atYEnd;
            }

            // A left press focuses the message under it and goes on, so a drag
            // still selects; a right-click opens the message's menu.
            MouseArea {
                z: 5
                width: scroller.width
                height: Math.max(scroller.contentHeight, scroller.height)
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: mouse => {
                    const index = detail.messageAt(mapToItem(conversation, mouse.x, mouse.y));
                    if (mouse.button === Qt.LeftButton) {
                        detail.pressing = true;
                        detail.focusMessage(index);
                        detail.pressing = false;
                        mouse.accepted = false;
                    } else if (index >= 0) {
                        const id = detail.item.id;
                        root.menuRequested(() => root.messageMenu(id, index), mapToItem(null, mouse.x, mouse.y, 0, 0), false);
                    }
                }
            }

            // Markdown text lays out after the first pass, so wait for the heights to stop moving.
            Timer {
                id: settle
                interval: 50
                onTriggered: if (scroller.follow)
                    scroller.toEnd()
            }

            // Inset by the focus outline.
            Column {
                id: conversation
                x: 4
                y: 4
                width: scroller.width - 2 * x
                spacing: 10

                Repeater {
                    id: messages
                    model: detail.item.messages

                    // Not the Loader itself: a focus scope would hand focus back to a hidden editor.
                    delegate: Item {
                        id: message

                        required property var modelData
                        required property int index

                        // Your own message's inline editor.
                        function edit() {
                            if (modelData.kind === "user" && !detail.running && detail.item.sessionId !== "")
                                loader.item.edit();
                        }

                        function menuScope() {
                            return {
                                title: "Message",
                                rows: Actions.messageRows(detail.item, index, root.selection ? root.selection.selectedText : "")
                            };
                        }

                        width: conversation.width
                        height: loader.height
                        activeFocusOnTab: index === detail.tabMessage

                        onActiveFocusChanged: if (activeFocus) {
                            detail.current = index;
                            if (!detail.pressing)
                                scroller.reveal(message);
                        }

                        // Keys from the editor arrive here too; they act only on the focused message.
                        Keys.onPressed: event => {
                            if (!activeFocus)
                                return;
                            const fold = modelData.kind === "tools";
                            if (event.key === Qt.Key_J || event.key === Qt.Key_Down)
                                detail.focusMessage(index + 1);
                            else if (event.key === Qt.Key_K || event.key === Qt.Key_Up)
                                detail.focusMessage(index - 1);
                            else if (fold && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space))
                                loader.item.expanded = !loader.item.expanded;
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                message.edit();
                            else if (event.matches(StandardKey.Copy))
                                root.copy(root.selection ? root.selection.selectedText : Actions.messageText(modelData));
                            else if (event.key === Qt.Key_Escape)
                                root.leaveField();
                            else
                                return;
                            event.accepted = true;
                        }

                        Rectangle {
                            visible: message.activeFocus
                            anchors.fill: parent
                            anchors.margins: -conversation.y
                            radius: 8
                            color: "transparent"
                            border.color: root.shell.palette.dim
                            border.width: 1
                        }

                        Loader {
                            id: loader
                            width: parent.width
                            sourceComponent: message.modelData.kind === "user" ? userMessage : message.modelData.kind === "tools" ? toolMessage : assistantMessage

                            // What you sent, on the right.
                            Component {
                                id: userMessage

                                Item {
                                    id: userItem

                                    property bool editing: false

                                    function edit() {
                                        editField.text = message.modelData.text;
                                        editing = true;
                                        editField.focusInput();
                                    }

                                    height: editing ? editor.height : bubble.height

                                    Text {
                                        id: measure
                                        visible: false
                                        font.family: Ui.Fonts.mono
                                        font.pixelSize: 14
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

                                        Blocks {
                                            id: bubbleText
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            text: message.modelData.text
                                        }
                                    }

                                    // Branches the investigation from this message; the original is kept.
                                    IconBtn {
                                        visible: !userItem.editing && !detail.running && detail.item.sessionId !== ""
                                        anchors.right: bubble.left
                                        anchors.rightMargin: 6
                                        anchors.verticalCenter: bubble.verticalCenter
                                        activeFocusOnTab: false
                                        text: Format.icons.draft
                                        onClicked: userItem.edit()
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
                                                    message.forceActiveFocus();
                                                }
                                            }
                                            Btn {
                                                label: "Cancel"
                                                onClicked: {
                                                    userItem.editing = false;
                                                    message.forceActiveFocus();
                                                }
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

                                    Blocks {
                                        width: parent.width
                                        text: message.modelData.text
                                    }

                                    IconBtn {
                                        activeFocusOnTab: false
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
                                        color: toolMouse.containsMouse ? root.shell.palette.fg : root.shell.palette.off
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
                }

                Text {
                    visible: detail.item.status === "failed"
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: root.shell.palette.rose
                    font.family: Ui.Fonts.mono
                    font.pixelSize: 14
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
                width: parent.width - followSettings.width - sendButton.width - 16
                readOnly: !detail.canFollowUp
                placeholder: detail.running ? "Claude is working…" : "Ask a follow-up…"
                onSubmitted: detail.send()
            }

            SettingChips {
                id: followSettings
            }

            Btn {
                id: sendButton
                icon: Format.icons.send
                label: "Send"
                enabled: detail.canFollowUp
                opacity: enabled ? 1 : 0.4
                onClicked: detail.send()
            }
        }
    }
}
