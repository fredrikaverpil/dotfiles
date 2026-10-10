import QtQuick
import Quickshell
import Quickshell.Io
import "../../Ui" as Ui

import "GcloudModel.js" as Model

// Whether the active gcloud account, and the application default credentials
// (ADC) that client libraries use, still yield an access token. Checks at
// start, hourly, and after every action. Every check and action runs gcloud;
// the shell never reads a token.
Ui.Plugin {
    id: plugin

    name: "gcloud-auth"
    // The last check that succeeded, null until one does: { accounts, active, ok, reason }.
    property var auth: null
    property bool failed: false
    // The last ADC check that succeeded, null until one does: { ok, reason }.
    property var adc: null
    property bool adcFailed: false
    // A refresh asked for while a check ran.
    property bool pending: false
    // The check in flight: { accounts, active }.
    property var checking: null
    // Logged out until a check says otherwise.
    readonly property bool loggedIn: auth !== null && auth.ok
    readonly property string status: failed ? "Check failed" : !auth ? "Checking…" : auth.ok ? "Logged in as " + auth.active : auth.active ? "Logged out: " + auth.active : "No active account"
    readonly property bool adcLoggedIn: adc !== null && adc.ok
    readonly property string adcStatus: adcFailed ? "ADC: check failed" : !adc ? "ADC: checking…" : adc.ok ? "ADC: logged in" : "ADC: logged out"
    // Filled (and green in the bar) while gcloud is logged in, a check while ADC
    // is, struck through while neither is.
    readonly property string icon: loggedIn ? (adcLoggedIn ? "\u{F0160}" : "\u{F015F}") : adcLoggedIn ? "\u{F12CC}" : "\u{F0164}"

    // Always shown: no state is an alert. Left-click logs in to gcloud, else to
    // ADC, whichever is out first; with both in it refreshes.
    barIndicator: ({
            label: plugin.icon,
            foreground: plugin.loggedIn ? plugin.shell.palette.leaf : plugin.shell.palette.off,
            action: () => !plugin.loggedIn ? plugin.logIn() : !plugin.adcLoggedIn ? plugin.logInAdc() : plugin.refresh()
        })
    menuItems: Object.assign({
        "plugins.gcloud-auth": {
            icon: plugin.icon,
            label: "gcloud auth"
        },
        "plugins.gcloud-auth.status": {
            icon: plugin.loggedIn ? "\u{F015F}" : "\u{F0164}",
            label: plugin.status,
            enabled: false
        },
        "plugins.gcloud-auth.adc": {
            icon: plugin.adcLoggedIn ? "\u{F0160}" : "\u{F0164}",
            label: plugin.adcStatus,
            enabled: false
        }
    }, plugin.accountItems(), {
        "plugins.gcloud-auth.refresh": {
            icon: "󰑐",
            label: "Refresh now",
            action: () => plugin.refresh()
        },
        "plugins.gcloud-auth.login": {
            icon: "\u{F0342}",
            label: "Log in",
            enabled: !plugin.loggedIn && !login.running,
            action: () => plugin.logIn()
        },
        "plugins.gcloud-auth.loginAdc": {
            icon: "\u{F0342}",
            label: "Log in ADC",
            enabled: !plugin.adcLoggedIn && !adcLogin.running,
            action: () => plugin.logInAdc()
        }
    })

    // Items, not a provider, so a root search finds an account.
    function accountItems() {
        const items = {};
        const accounts = plugin.auth ? plugin.auth.accounts : [];
        accounts.forEach((account, index) => {
            items["plugins.gcloud-auth." + index] = {
                icon: plugin.shell.menu.radio(account.status === "ACTIVE"),
                label: account.account,
                action: () => plugin.activate(account.account)
            };
        });
        return items;
    }

    // `running` is read here, not through a binding: it notifies only after a
    // Process's exited handler.
    function refresh() {
        if (list.running || token.running || adcToken.running) {
            plugin.pending = true;
            return;
        }
        list.running = true;
        adcToken.running = true;
    }

    // Runs a refresh asked for while checks ran, once all have ended.
    function settle() {
        if (plugin.pending && !list.running && !token.running && !adcToken.running) {
            plugin.pending = false;
            plugin.refresh();
        }
    }

    function logIn() {
        login.running = true;
    }

    function logInAdc() {
        adcLogin.running = true;
    }

    function activate(account) {
        switcher.command = ["timeout", "30", "gcloud", "config", "set", "account", account];
        switcher.running = true;
    }

    // Ends a check. A failed one (null) keeps the last result.
    function finish(next) {
        plugin.failed = next === null;
        if (next) {
            if (Model.loggedOut(plugin.auth, next))
                Quickshell.execDetached(["notify-send", "-a", "gcloud auth", "Logged out: " + next.active, next.reason]);
            plugin.auth = next;
        }
        plugin.settle();
    }

    IpcHandler {
        target: "gcloud-auth"

        function refresh(): void {
            plugin.refresh();
        }
        function login(): void {
            plugin.logIn();
        }
        function loginAdc(): void {
            plugin.logInAdc();
        }
        function status(): string {
            return plugin.status;
        }
        function adcStatus(): string {
            return plugin.adcStatus;
        }
    }

    Timer {
        interval: 60 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: plugin.refresh()
    }

    Process {
        id: list
        command: ["timeout", "30", "gcloud", "auth", "list", "--format=json"]
        stdout: StdioCollector {
            id: listOut
        }
        onExited: {
            const accounts = Model.parseAccounts(listOut.text);
            const active = accounts ? Model.activeAccount(accounts) : "";
            if (!active) {
                plugin.finish(accounts ? {
                    accounts: accounts,
                    active: "",
                    ok: false,
                    reason: ""
                } : null);
                return;
            }
            plugin.checking = {
                accounts: accounts,
                active: active
            };
            token.command = ["timeout", "30", "gcloud", "auth", "print-access-token", "--account=" + active];
            token.running = true;
        }
    }

    // No stdout collector: the token is discarded unread.
    Process {
        id: token
        stderr: StdioCollector {
            id: tokenErr
        }
        onExited: function (exitCode) {
            const result = Model.token(exitCode, tokenErr.text, Model.LOGIN);
            plugin.finish(result ? Object.assign({}, plugin.checking, result) : null);
        }
    }

    // Like token, and independent of the active account. A failed check keeps
    // the last result.
    Process {
        id: adcToken
        command: ["timeout", "30", "gcloud", "auth", "application-default", "print-access-token"]
        stderr: StdioCollector {
            id: adcErr
        }
        onExited: function (exitCode) {
            const result = Model.token(exitCode, adcErr.text, Model.ADC_LOGIN);
            plugin.adcFailed = result === null;
            if (result)
                plugin.adc = result;
            plugin.settle();
        }
    }

    // Opens the browser; gcloud adds the account and makes it active.
    Process {
        id: login
        command: ["timeout", "300", "gcloud", "auth", "login", "--brief"]
        onExited: plugin.refresh()
    }

    // Opens the browser; writes the ADC file client libraries read.
    Process {
        id: adcLogin
        command: ["timeout", "300", "gcloud", "auth", "application-default", "login"]
        onExited: plugin.refresh()
    }

    Process {
        id: switcher
        onExited: plugin.refresh()
    }
}
