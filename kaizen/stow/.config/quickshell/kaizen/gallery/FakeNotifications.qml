import QtQuick

import "../modules/notifications/NotificationModel.js" as Model

// The notification service's members the history view and the bell read, without a notification server.
QtObject {
    id: fake

    readonly property real now: new Date(2026, 10, 12, 14, 2, 7).getTime()
    // A history row as the service saves it, `minutes` ago.
    function row(app, appIcon, summary, body, minutes, extra) {
        return Object.assign({
            app: app,
            appIcon: appIcon,
            summary: summary,
            body: body,
            image: "",
            icon: "",
            badgeIcon: "",
            badgeEmoji: "",
            border: "",
            animation: "",
            actions: [],
            urgency: 1,
            timestamp: now - minutes * 60000
        }, extra || {});
    }
    readonly property var several: [row("Slack", "slack", "Reminder: Design review", "Starts in 5 minutes in #kaizen. Bring the gallery screenshots.", 3, {
            urgency: 2,
            border: "rose",
            animation: "alarm",
            actions: [
                {
                    text: "Open Slack",
                    command: ["xdg-open", "slack://open"],
                    env: {}
                }
            ]
        }), row("Firefox", "firefox", "Download finished", "nixos-26.05-x86_64.iso", 2), row("Signal", "signal-desktop", "Johanna", "Can you pick up the kids at five? I'll be stuck at work until six, and the after-school club closes at half past five today.", 9), row("kaizen", "", "Recording saved", "~/Videos/Recordings/2026-11-12 13-58-01.mp4", 14, {
            actions: [
                {
                    text: "Open folder",
                    command: ["xdg-open", "~/Videos/Recordings"],
                    env: {}
                },
                {
                    text: "Play",
                    command: ["xdg-open", "~/Videos/Recordings/2026-11-12 13-58-01.mp4"],
                    env: {}
                }
            ]
        }), row("Thunderbird", "thunderbird", "3 new messages", "", 1500)]
    // Every rule look a card can take, each followed by a plain card.
    readonly property var looks: [
        {
            border: "sky",
            animation: "orbit"
        },
        {},
        {
            border: "rose",
            animation: "heartbeat"
        },
        {},
        {
            border: "leaf",
            animation: "glow"
        },
        {},
        {
            border: "wood",
            animation: "lightning"
        },
        {},
        {
            border: "rose",
            animation: "alarm"
        },
        {}
    ]
    readonly property var many: {
        const list = [];
        for (let i = 0; i < 30; i++)
            list.push(row(["Slack", "Signal", "Firefox"][i % 3], ["slack", "signal-desktop", "firefox"][i % 3], "Message " + (i + 1), "Held back while the screen was shared.", i * 7, looks[i % looks.length]));
        return list;
    }
    readonly property var scenarios: ({
            "DnD on": {
                doNotDisturb: true,
                historyRows: several
            },
            "DnD off": {
                doNotDisturb: false,
                historyRows: several
            },
            "Many": {
                doNotDisturb: true,
                historyRows: many
            },
            "Empty": {
                doNotDisturb: false,
                historyRows: []
            }
        })

    property bool doNotDisturb: true
    property var historyRows: several
    readonly property bool dndOverdue: false
    readonly property bool criticalHeld: false

    function setDoNotDisturb(value) {
        doNotDisturb = !!value;
    }

    function clearHistory() {
        historyRows = [];
    }

    function removeHistory(index) {
        historyRows = Model.withoutIndex(historyRows, index);
    }
}
