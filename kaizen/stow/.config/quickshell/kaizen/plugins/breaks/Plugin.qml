import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import qs.Ui as Ui

import "BreaksModel.js" as Model
import "../../Ui/Hold.js" as Hold

// How long you have been at the computer without a break, with a card for each
// reminder as it comes due. A session ends after idleMinutes without input, or
// when the screen locks or the curtain goes up. A session survives a shell
// restart shorter than idleMinutes.
Ui.Plugin {
    id: plugin

    readonly property var settings: Model.settings(plugin.config)
    readonly property var reminders: settings.reminders
    readonly property string statePath: Ui.Paths.state + "/plugins/breaks/state.json"
    property bool stateLoaded: false

    // Holds reminders back while the session keeps counting; DnD turns it on.
    property bool holding: false
    // Reasons holding, DnD's, and whether a hold turned it on.
    property var holds: []
    property bool holdOwned: false
    // When the session started; 0 while there is none.
    property real sessionStart: 0
    // Each reminder's shows this session, by id; one due beyond them is
    // pending.
    property var shown: ({})
    // Each reminder's shows since the shell started, by id: picks its detail.
    property var rotation: ({})
    // The reminder counting down on its card, with its detail; null for none.
    property var counting: null
    property int left: 0
    property real now: Date.now()

    readonly property bool covered: plugin.shell.lock.locked || plugin.shell.curtain.active
    readonly property bool dnd: plugin.shell.dnd.active
    readonly property bool held: holding || covered
    readonly property bool tracking: !covered && !idleMonitor.isIdle
    readonly property real elapsed: sessionStart > 0 ? now - sessionStart : 0
    readonly property string phase: Model.state(sessionStart > 0, elapsed, reminders, holding)
    readonly property var indicator: Model.indicator(phase, elapsed)

    barIndicator: ({
            label: plugin.indicator.text ? plugin.indicator.icon + " " + plugin.indicator.text : plugin.indicator.icon,
            foreground: plugin.shell.palette[plugin.indicator.role],
            action: () => plugin.remind()
        })
    menuItems: ({
            "plugins.breaks": {
                icon: plugin.indicator.icon,
                label: "Breaks"
            },
            "plugins.breaks.status": {
                icon: plugin.indicator.icon,
                label: Model.status(plugin.phase, plugin.elapsed),
                enabled: false
            },
            "plugins.breaks.new": {
                icon: "󰑐",
                label: "New session",
                action: () => plugin.newSession()
            },
            "plugins.breaks.hold": {
                icon: plugin.shell.menu.checkbox(plugin.holding),
                label: "Hold reminders",
                action: () => plugin.setHolding(!plugin.holding)
            },
            "plugins.breaks.show": {
                icon: "\u{F0176}",
                label: "Show reminder",
                action: () => plugin.remind()
            }
        })

    function start() {
        plugin.now = Date.now();
        plugin.sessionStart = plugin.now;
        plugin.shown = {};
    }

    function end() {
        plugin.sessionStart = 0;
        plugin.shown = {};
        plugin.counting = null;
    }

    function newSession() {
        if (plugin.tracking)
            plugin.start();
        else
            plugin.end();
    }

    // The session time, large.
    function remind() {
        plugin.counting = null;
        osd.headline = Model.duration(plugin.elapsed);
        osd.detail = "Time for a break";
        osd.show();
    }

    // Shows a reminder, counting down its seconds if it has any.
    function show(r) {
        const n = plugin.rotation[r.id] || 0;
        plugin.rotation[r.id] = n + 1;
        plugin.save();
        plugin.counting = r.seconds > 0 ? {
            reminder: r,
            detail: Model.detail(r, n)
        } : null;
        plugin.left = r.seconds;
        // Only with a count: restart() runs the timer whatever its binding says.
        if (plugin.counting)
            countdown.restart();
        plugin.display(r, Model.detail(r, n));
    }

    // Shows a reminder's card, or refreshes its countdown; each show restarts
    // the card's own hide.
    function display(r, detail) {
        const count = r.seconds > 0 ? (plugin.left > 0 ? plugin.left + " s" : "done") : "";
        osd.headline = r.icon;
        osd.detail = [r.title, detail, count].filter(s => s).join(" · ");
        osd.show();
    }

    // Shows a reminder that came due; one due while held back is skipped.
    function tick() {
        plugin.now = Date.now();
        if (plugin.sessionStart > 0) {
            const picked = Model.pick(plugin.reminders, plugin.elapsed, plugin.shown);
            plugin.shown = picked.shown;
            if (picked.reminder && !plugin.held)
                plugin.show(picked.reminder);
        }
    }

    // Set by hand: no hold turns it off.
    function setHolding(value) {
        plugin.holdOwned = false;
        plugin.holding = !!value;
        plugin.save();
    }

    function hold(reason, on) {
        const next = Hold.hold({
            on: plugin.holding,
            holds: plugin.holds,
            owned: plugin.holdOwned
        }, reason, on);
        plugin.holds = next.holds;
        plugin.holdOwned = next.owned;
        plugin.holding = next.on;
        plugin.save();
    }

    function save() {
        if (plugin.stateLoaded)
            stateFile.setText(Model.stateText(plugin.holding, plugin.holdOwned, plugin.rotation, plugin.sessionStart, plugin.shown, Date.now()));
    }

    // Before the first start: a session the restart broke resumes.
    function load() {
        const r = Model.restored(stateFile.text(), Date.now(), plugin.settings.idleMinutes * 60 * 1000);
        if (!r.valid)
            console.warn("breaks: ignoring invalid saved state");
        plugin.holds = [];
        plugin.holdOwned = r.owned;
        plugin.holding = r.holding;
        plugin.rotation = r.rotation;
        if (plugin.tracking && r.sessionStart > 0) {
            plugin.now = Date.now();
            plugin.sessionStart = r.sessionStart;
            plugin.shown = r.shown;
        } else if (plugin.tracking) {
            plugin.start();
        }
        plugin.stateLoaded = true;
        // DnD may have changed while the shell was down.
        plugin.hold("dnd", plugin.dnd);
    }

    onTrackingChanged: tracking ? start() : end()
    onDndChanged: hold("dnd", dnd)
    onSessionStartChanged: save()
    onShownChanged: save()
    onHeldChanged: {
        if (held)
            counting = null;
        tick();
    }
    Component.onCompleted: load()

    IdleMonitor {
        id: idleMonitor
        timeout: plugin.settings.idleMinutes * 60
        // An inhibitor, such as a video call's, keeps the session going.
        respectInhibitors: true
    }

    Timer {
        interval: 10 * 1000
        running: plugin.sessionStart > 0
        repeat: true
        onTriggered: plugin.tick()
    }

    // Keeps the saved session's seen time current.
    Timer {
        interval: 60 * 1000
        running: plugin.sessionStart > 0
        repeat: true
        onTriggered: plugin.save()
    }

    Timer {
        id: countdown
        interval: 1000
        running: plugin.counting !== null
        repeat: true
        onTriggered: {
            plugin.left -= 1;
            plugin.display(plugin.counting.reminder, plugin.counting.detail);
            if (plugin.left <= 0)
                plugin.counting = null;
        }
    }

    FileView {
        id: stateFile
        path: plugin.statePath
        atomicWrites: true
        // Blocks the first read, so load() has it.
        blockLoading: true
        printErrors: false
    }

    Ui.LargeOsd {
        id: osd
        shell: plugin.shell
        namespace: "kaizen-breaks"
        // Ends the countdown, whose next second would show it again.
        onDismissed: plugin.counting = null
    }

    IpcHandler {
        target: "breaks"

        function status(): string {
            return Model.status(plugin.phase, plugin.elapsed);
        }
        function newSession(): void {
            plugin.newSession();
        }
        function holdState(): string {
            return plugin.holding ? "on" : "off";
        }
        function toggleHold(): string {
            plugin.setHolding(!plugin.holding);
            return holdState();
        }
        function setHold(value: string): string {
            plugin.setHolding(Hold.flag(value));
            return holdState();
        }
        function remind(): void {
            plugin.remind();
        }
        function dismiss(): void {
            osd.dismiss();
        }
    }
}
