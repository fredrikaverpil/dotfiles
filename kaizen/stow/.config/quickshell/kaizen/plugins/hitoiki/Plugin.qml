import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import qs.Ui as Ui

import "HitoikiModel.js" as Model

// How long you have been at the computer without a break, with a card for each
// reminder as it comes due. A session ends after idleMinutes without input, or
// when the screen locks or the curtain goes up. Nothing survives a shell
// restart.
Ui.Plugin {
    id: plugin

    readonly property var settings: Model.settings(plugin.config)
    readonly property var reminders: settings.reminders

    property bool paused: false
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

    readonly property bool away: plugin.shell.lock.locked || plugin.shell.curtain.active
    readonly property bool held: plugin.shell.dnd.active || away
    readonly property bool tracking: !paused && !away && !idleMonitor.isIdle
    readonly property real elapsed: sessionStart > 0 ? now - sessionStart : 0
    readonly property string phase: Model.state(paused, sessionStart > 0, elapsed, reminders)
    readonly property var indicator: Model.indicator(phase, elapsed)

    barIndicator: ({
            label: plugin.indicator.text ? plugin.indicator.icon + " " + plugin.indicator.text : plugin.indicator.icon,
            foreground: plugin.shell.palette[plugin.indicator.role],
            action: () => plugin.remind()
        })
    menuItems: ({
            "plugins.hitoiki": {
                icon: plugin.indicator.icon,
                label: "hitoiki"
            },
            "plugins.hitoiki.status": {
                icon: plugin.indicator.icon,
                label: Model.status(plugin.phase, plugin.elapsed),
                enabled: false
            },
            "plugins.hitoiki.new": {
                icon: "󰑐",
                label: "New session",
                action: () => plugin.newSession()
            },
            "plugins.hitoiki.pause": {
                icon: plugin.shell.menu.checkbox(plugin.paused),
                label: "Pause tracking",
                action: () => plugin.paused ? plugin.resume() : plugin.pause()
            },
            "plugins.hitoiki.show": {
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
        plugin.paused = false;
        if (plugin.tracking)
            plugin.start();
        else
            plugin.end();
    }

    function pause() {
        plugin.paused = true;
    }

    function resume() {
        plugin.paused = false;
    }

    // The session time, large.
    function remind() {
        plugin.counting = null;
        osd.headline = Model.duration(plugin.elapsed);
        osd.detail = "一息 · time for a breather";
        osd.show();
    }

    // Shows a reminder, counting down its seconds if it has any.
    function show(r) {
        const n = plugin.rotation[r.id] || 0;
        plugin.rotation[r.id] = n + 1;
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
        osd.detail = ["一息", r.title, detail, count].filter(s => s).join(" · ");
        osd.show();
    }

    // Shows a reminder that came due, once nothing holds it back.
    function tick() {
        plugin.now = Date.now();
        if (plugin.sessionStart > 0 && !plugin.held) {
            const picked = Model.pick(plugin.reminders, plugin.elapsed, plugin.shown);
            plugin.shown = picked.shown;
            if (picked.reminder)
                plugin.show(picked.reminder);
        }
    }

    onTrackingChanged: tracking ? start() : end()
    onHeldChanged: {
        if (held)
            counting = null;
        tick();
    }
    Component.onCompleted: if (tracking)
        start()

    IdleMonitor {
        id: idleMonitor
        enabled: !plugin.paused
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

    Ui.LargeOsd {
        id: osd
        shell: plugin.shell
        namespace: "kaizen-hitoiki"
    }

    IpcHandler {
        target: "hitoiki"

        function status(): string {
            return Model.status(plugin.phase, plugin.elapsed);
        }
        function newSession(): void {
            plugin.newSession();
        }
        function pause(): void {
            plugin.pause();
        }
        function resume(): void {
            plugin.resume();
        }
        function remind(): void {
            plugin.remind();
        }
    }
}
