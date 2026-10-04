import QtQuick
import QtTest
import "../modules/notifications/NotificationLogic.js" as Notification

TestCase {
    name: "NotificationLogic"

    function test_notification_snapshots_normalize_optional_fields_and_preserve_supplied_time() {
        compare(Notification.asString(null), "");
        compare(Notification.asString(4), "4");
        compare(Notification.snapshotOf({
            appName: "Mail",
            urgency: 2
        }, 123), {
            app: "Mail",
            appIcon: "",
            summary: "",
            body: "",
            image: "",
            icon: "",
            badgeEmoji: "",
            border: "",
            borderAnimation: "",
            actions: [],
            urgency: 2,
            timestamp: 123
        });
    }

    function test_notification_urgency_is_set_by_notifications_matching_every_field_of_a_rule() {
        const rules = Notification.compileRules([
            {
                match: {
                    app: "^Slack$",
                    summary: " in #?alerts$"
                },
                urgency: "critical"
            },
            {
                match: {
                    app: "^Slack$",
                    summary: " in #general$"
                }
            },
            {
                match: {
                    body: "["
                },
                urgency: "critical"
            },
            {
                match: {},
                urgency: "critical"
            },
            {
                urgency: "critical"
            },
            {
                match: {
                    sumary: "x"
                },
                urgency: "critical"
            },
        ]);

        compare(Notification.urgencyOf({
            appName: "Slack",
            summary: "[x] in #alerts",
            urgency: 1
        }, rules), 2);
        compare(Notification.urgencyOf({
            appName: "Slack",
            summary: "New message in alerts",
            urgency: 1
        }, rules), 2);
        compare(Notification.urgencyOf({
            appName: "Slack",
            summary: "[x] in #general",
            urgency: 1
        }, rules), 1);
        compare(Notification.urgencyOf({
            appName: "Chromium",
            summary: "[x] in #alerts",
            urgency: 1
        }, rules), 1);
        compare(Notification.urgencyOf({
            appName: "Mail",
            summary: "x",
            body: "[",
            urgency: 1
        }, rules), 1);
        compare(Notification.urgencyOf({
            appName: "Slack",
            summary: "[x] in #alerts",
            urgency: 1
        }), 1);
        compare(Notification.durationFor({
            appName: "Slack",
            summary: "[x] in #alerts",
            urgency: 1,
            expireTimeout: 1
        }, 0, 2, rules), 0);
        compare(Notification.snapshotOf({
            appName: "Slack",
            summary: "[x] in #alerts",
            urgency: 1
        }, 123, rules), {
            app: "Slack",
            appIcon: "",
            summary: "[x] in #alerts",
            body: "",
            image: "",
            icon: "",
            badgeEmoji: "",
            border: "",
            borderAnimation: "",
            actions: [],
            urgency: 2,
            timestamp: 123
        });
    }

    function test_notification_urgency_comes_from_the_first_matching_rule_with_one() {
        const rules = Notification.compileRules([
            {
                match: {
                    app: "^Slack$",
                    summary: " in #?alerts-dev$"
                },
                urgency: "normal"
            },
            {
                match: {
                    app: "^Slack$",
                    summary: " from Bot$"
                }
            },
            {
                match: {
                    app: "^Slack$",
                    summary: " from Bot$"
                },
                urgency: "low"
            },
            {
                match: {
                    app: "^Slack$"
                },
                urgency: "critical"
            },
        ]);

        compare(Notification.urgencyOf({
            appName: "Slack",
            summary: "[x] in #alerts-dev",
            urgency: 2
        }, rules), 1);
        compare(Notification.urgencyOf({
            appName: "Slack",
            summary: "[x] from Bot",
            urgency: 2
        }, rules), 0);
        compare(Notification.urgencyOf({
            appName: "Slack",
            summary: "[x] in #general",
            urgency: 0
        }, rules), 2);
        compare(Notification.urgencyOf({
            appName: "Mail",
            urgency: 2
        }, rules), 2);
        compare(Notification.durationFor({
            appName: "Slack",
            summary: "[x] from Bot",
            urgency: 2,
            expireTimeout: 1
        }, 0, 2, rules), 5000);
    }

    function test_notification_dedup_comes_from_the_first_matching_rule_with_a_group() {
        const rules = Notification.compileRules([
            {
                match: {
                    app: "^Chromium$",
                    body: "^calendar\\.google\\.com\\n"
                },
                dedup: {
                    group: "calendar",
                    keep: true
                }
            },
            {
                match: {
                    app: "^Slack$",
                    summary: " from Google Calendar$"
                },
                urgency: "critical"
            },
            {
                match: {
                    app: "^Slack$",
                    summary: " from Google Calendar$"
                },
                dedup: {
                    group: "calendar",
                    keep: false
                }
            },
            {
                match: {
                    app: "^Slack$"
                },
                dedup: {
                    group: "slack",
                    keep: false
                }
            },
        ]);

        compare(Notification.dedupOf({
            appName: "Chromium",
            body: "calendar.google.com\n09:00 – 09:30"
        }, rules), {
            group: "calendar",
            keep: true
        });
        compare(Notification.dedupOf({
            appName: "Chromium",
            body: "mail.google.com\ncalendar.google.com"
        }, rules), null);
        compare(Notification.dedupOf({
            appName: "Slack",
            summary: "[x] from Google Calendar"
        }, rules), {
            group: "calendar",
            keep: false
        });
        compare(Notification.dedupOf({
            appName: "Slack",
            summary: "[x] in #general"
        }, rules), {
            group: "slack",
            keep: false
        });
        compare(Notification.dedupOf({
            appName: "Slack",
            summary: "[x] from Google Calendar"
        }), null);
    }

    function test_notification_collapse_is_the_same_object_for_every_toast_of_its_rule() {
        const rules = Notification.compileRules([
            {
                match: {
                    app: "^Slack$",
                    body: "^Reviews assigned"
                },
                collapse: {
                    summary: null,
                    body: "Several"
                }
            },
            {
                match: {
                    app: "^Slack$"
                },
                collapse: null
            },
        ]);

        const first = Notification.ruleValue({
            appName: "Slack",
            body: "Reviews assigned to you on a"
        }, rules, "collapse");
        const second = Notification.ruleValue({
            appName: "Slack",
            body: "Reviews assigned to you on b"
        }, rules, "collapse");
        compare(first, {
            summary: null,
            body: "Several"
        });
        verify(first === second);
        compare(Notification.ruleValue({
            appName: "Slack",
            body: "Hi"
        }, rules, "collapse"), "");
    }

    function test_notification_icon_comes_from_the_first_matching_rule_with_one() {
        const rules = Notification.compileRules([
            {
                match: {
                    app: "^Slack$",
                    summary: " from Google Calendar$"
                },
                urgency: "critical",
                icon: null
            },
            {
                match: {
                    app: "^Slack$",
                    summary: " from GitHub$"
                },
                icon: "/nix/store/x-github.svg"
            },
            {
                match: {
                    app: "^Slack$"
                },
                icon: "image://icon/slack"
            },
        ]);

        compare(Notification.iconOf({
            appName: "Slack",
            summary: "[x] from GitHub"
        }, rules), "file:///nix/store/x-github.svg");
        compare(Notification.iconOf({
            appName: "Slack",
            summary: "[x] from Google Calendar"
        }, rules), "image://icon/slack");
        compare(Notification.iconOf({
            appName: "Chromium",
            summary: "[x] from GitHub"
        }, rules), "");
        compare(Notification.iconOf({
            appName: "Slack",
            summary: "[x] from GitHub"
        }), "");
        compare(Notification.snapshotOf({
            appName: "Slack",
            summary: "[x] from GitHub",
            urgency: 1
        }, 123, rules), {
            app: "Slack",
            appIcon: "",
            summary: "[x] from GitHub",
            body: "",
            image: "",
            icon: "file:///nix/store/x-github.svg",
            badgeEmoji: "",
            border: "",
            borderAnimation: "",
            actions: [],
            urgency: 1,
            timestamp: 123
        });
    }

    function test_notification_border_comes_from_the_first_matching_rule_with_one() {
        const rules = Notification.compileRules([
            {
                match: {
                    app: "^Slack$",
                    summary: " in #?alerts$"
                },
                urgency: "critical",
                border: "rose",
                borderAnimation: "orbit"
            },
            {
                match: {
                    app: "^Slack$",
                    summary: " in #?alerts-dev$"
                },
                urgency: "critical",
                border: "water"
            },
        ]);

        compare(Notification.ruleValue({
            appName: "Slack",
            summary: "[x] in #alerts"
        }, rules, "border"), "rose");
        compare(Notification.ruleValue({
            appName: "Slack",
            summary: "[x] in #alerts-dev"
        }, rules, "border"), "water");
        compare(Notification.ruleValue({
            appName: "Slack",
            summary: "[x] in #alerts-dev"
        }, rules, "borderAnimation"), "");
        compare(Notification.ruleValue({
            appName: "Slack",
            summary: "[x] in #general"
        }, rules, "border"), "");
        compare(Notification.ruleValue({
            appName: "Slack",
            summary: "[x] in #alerts"
        }, undefined, "border"), "");
        compare(Notification.snapshotOf({
            appName: "Slack",
            summary: "[x] in #alerts",
            urgency: 1
        }, 123, rules), {
            app: "Slack",
            appIcon: "",
            summary: "[x] in #alerts",
            body: "",
            image: "",
            icon: "",
            badgeEmoji: "",
            border: "rose",
            borderAnimation: "orbit",
            actions: [],
            urgency: 2,
            timestamp: 123
        });
    }

    function test_notification_badge_emoji_comes_from_the_first_matching_rule_with_one() {
        const rules = Notification.compileRules([
            {
                match: {
                    app: "^Signal$",
                    summary: " Averpil$"
                },
                badgeEmoji: "❤️"
            },
        ]);

        compare(Notification.snapshotOf({
            appName: "Signal",
            summary: "Bob Averpil",
            image: "image://qsimage/1",
            urgency: 1
        }, 123, rules), {
            app: "Signal",
            appIcon: "",
            summary: "Bob Averpil",
            body: "",
            image: "image://qsimage/1",
            icon: "",
            badgeEmoji: "❤️",
            border: "",
            borderAnimation: "",
            actions: [],
            urgency: 1,
            timestamp: 123
        });
    }

    function test_notification_heartbeat_beats_twice_then_rests() {
        const lub = Notification.heartbeat(150);
        const dub = Notification.heartbeat(450);
        const rest = Notification.heartbeat(1500);

        fuzzyCompare(lub, 1, 0.01);
        fuzzyCompare(dub, 0.6, 0.01);
        fuzzyCompare(rest, 0, 0.01);
        verify(Notification.heartbeat(2400 + 150) === lub);
    }

    function test_notification_glow_breathes_in_and_out() {
        fuzzyCompare(Notification.glow(0), 0, 0.001);
        fuzzyCompare(Notification.glow(1600), 1, 0.001);
        fuzzyCompare(Notification.glow(800), 0.5, 0.001);
        fuzzyCompare(Notification.glow(3200 + 1600), 1, 0.001);
    }

    function test_notification_glow_flares_on_arrival_then_settles() {
        verify(Notification.glowFlare(0) === 1);
        fuzzyCompare(Notification.glowFlare(750), 0.125, 0.001);
        verify(Notification.glowFlare(1500) === 0);
        verify(Notification.glowFlare(-1) === 0);
        verify(Notification.glowFlare(NaN) === 0);
    }

    function test_notification_icon_sources_preserve_schemes_and_normalize_paths() {
        compare(Notification.iconSource("/tmp/icon.png"), "file:///tmp/icon.png");
        compare(Notification.iconSource("file:///tmp/icon.png"), "file:///tmp/icon.png");
        compare(Notification.iconSource("image://icon/mail"), "image://icon/mail");
        compare(Notification.iconSource("mail"), "mail");
        compare(Notification.iconSource(null), "");
    }

    function test_notification_shortcodes_map_every_alias_to_its_emoji() {
        const emoji = [
            {
                emoji: "👍",
                name: "thumbs up",
                shortcodes: ["+1", "thumbsup"]
            },
            {
                emoji: "🪾",
                name: "leafless tree",
                shortcodes: []
            },
            {
                emoji: "🏻",
                name: null,
                shortcodes: ["skin-tone-2"]
            },
        ];
        compare(Notification.shortcodesFrom(emoji), {
            "+1": "👍",
            thumbsup: "👍",
            "skin-tone-2": "🏻"
        });
        compare(Notification.shortcodesFrom([]), {});
    }

    function test_notification_emojify_replaces_known_shortcodes_only() {
        const codes = {
            hammer_and_wrench: "🛠️",
            memo: "📝",
            "+1": "👍",
            "skin-tone-2": "🏻"
        };
        compare(Notification.emojify("Up next: :hammer_and_wrench::memo: Sprint :+1::skin-tone-2: :custom: 10:30:00", codes), "Up next: 🛠️📝 Sprint 👍🏻 :custom: 10:30:00");
    }

    function test_notification_duration_honors_urgency_residency_and_bounds() {
        const low = 0;
        const critical = 2;
        compare(Notification.durationFor({
            urgency: critical,
            expireTimeout: 1
        }, low, critical), 0);
        compare(Notification.durationFor({
            urgency: 1,
            resident: true
        }, low, critical), 0);
        compare(Notification.durationFor({
            urgency: low,
            expireTimeout: 1
        }, low, critical), 5000);
        compare(Notification.durationFor({
            urgency: 1,
            expireTimeout: 1
        }, low, critical), 8000);
        compare(Notification.durationFor({
            urgency: 1,
            expireTimeout: 99999
        }, low, critical), 30000);
        compare(Notification.durationFor({
            urgency: 1,
            expireTimeout: "invalid"
        }, low, critical), 8000);
        compare(Notification.durationFor({
            urgency: 1,
            expireTimeout: 0
        }, low, critical), 0);
        compare(Notification.durationFor({
            urgency: 1,
            expireTimeout: -1
        }, low, critical), 8000);
    }

    function test_notification_capture_keeps_actions_and_hints_unprocessed() {
        compare(Notification.captureOf({
            id: 7,
            appName: "Slack",
            desktopEntry: "slack",
            summary: ":tada: hi",
            urgency: 1,
            expireTimeout: -1,
            actions: [
                {
                    identifier: "default",
                    text: "Open"
                }
            ],
            hints: {
                "sender-pid": 42
            }
        }, 123), {
            timestamp: 123,
            id: 7,
            app: "Slack",
            desktopEntry: "slack",
            appIcon: "",
            summary: ":tada: hi",
            body: "",
            image: "",
            urgency: 1,
            expireTimeout: -1,
            resident: false,
            transient: false,
            actions: [
                {
                    identifier: "default",
                    text: "Open"
                }
            ],
            hints: {
                "sender-pid": 42
            }
        });
    }

    function test_notification_app_id_prefers_the_desktop_entry() {
        compare(Notification.appIdOf({
            desktopEntry: "slack",
            appName: "Slack"
        }), "slack");
        compare(Notification.appIdOf({
            desktopEntry: "slack.desktop",
            appName: "Slack"
        }), "slack");
        compare(Notification.appIdOf({
            desktopEntry: "",
            appName: "Signal"
        }), "Signal");
        compare(Notification.appIdOf({}), "");
    }

    function test_notification_focus_pattern_is_the_matching_rules_else_the_apps_own_id() {
        const rules = Notification.compileRules([
            {
                match: {
                    app: "^Slack$",
                    summary: " from Google Calendar$"
                },
                focus: "^chrome-calendar"
            },
            {
                match: {
                    app: "^Slack$"
                }
            },
        ]);

        compare(Notification.focusPatternOf({
            appName: "Slack",
            desktopEntry: "slack",
            summary: "[x] from Google Calendar"
        }, rules), "^chrome-calendar");
        compare(Notification.focusPatternOf({
            appName: "Slack",
            desktopEntry: "slack",
            summary: "[x] from Egil"
        }, rules), "(?i)^slack$");
        compare(Notification.focusPatternOf({
            appName: "Mail",
            desktopEntry: "org.a.b"
        }, rules), "(?i)^org\\.a\\.b$");
        compare(Notification.focusPatternOf({}, rules), "");
    }

    function test_notification_buttons_skip_the_default_action() {
        const open = {
            identifier: "default",
            text: "Open"
        };
        const reply = {
            identifier: "reply",
            text: "Reply"
        };
        const mute = {
            identifier: "mute",
            text: "Mute"
        };
        compare(Notification.buttons([open, reply, mute]), [reply, mute]);
        compare(Notification.buttons([open]), []);
        compare(Notification.buttons(null), []);
    }

    function test_notification_actions_come_from_the_first_matching_rule_with_any() {
        const rules = Notification.compileRules([
            {
                match: {
                    app: "^Slack$",
                    summary: " in #?alerts$"
                },
                border: "rose",
                actions: []
            },
            {
                match: {
                    app: "^Slack$",
                    summary: " in #?alerts"
                },
                actions: [
                    {
                        label: "Escalate",
                        command: ["escalate"],
                        env: {
                            TEAM: "ops"
                        }
                    }
                ]
            },
            {
                match: {
                    app: "^Slack$"
                },
                actions: [
                    {
                        label: "Log",
                        command: ["log"]
                    }
                ]
            },
        ]);
        const escalate = {
            text: "Escalate",
            command: ["escalate"],
            env: {
                TEAM: "ops"
            }
        };

        compare(Notification.actionsOf({
            appName: "Slack",
            summary: "[x] in #alerts"
        }, rules), [escalate]);
        compare(Notification.actionsOf({
            appName: "Slack",
            summary: "[x] in #general"
        }, rules), [
            {
                text: "Log",
                command: ["log"],
                env: {}
            }
        ]);
        compare(Notification.actionsOf({
            appName: "Mail",
            summary: "[x] in #alerts"
        }, rules), []);
        compare(Notification.actionsOf({
            appName: "Slack",
            summary: "[x] in #alerts"
        }), []);
        compare(Notification.buttons([
            {
                identifier: "default",
                text: "Open"
            },
            {
                identifier: "reply",
                text: "Reply"
            }
        ], [escalate]), [
            {
                identifier: "reply",
                text: "Reply"
            },
            escalate]);
    }

    function test_notification_action_commands_carry_the_notification_and_the_actions_variables() {
        const record = {
            app: "Slack",
            summary: "[x] in #alerts",
            body: "a\nb"
        };
        const action = {
            text: "Escalate",
            command: ["escalate"],
            env: {
                TEAM: "ops"
            }
        };

        compare(Notification.commandOf(record, action), ["env", "NOTIFICATION_APP=Slack", "NOTIFICATION_SUMMARY=[x] in #alerts", "NOTIFICATION_BODY=a\nb", "TEAM=ops", "escalate",]);
    }
}
