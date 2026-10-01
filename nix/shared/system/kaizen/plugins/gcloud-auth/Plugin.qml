import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui as Ui

import "GcloudModel.js" as Model

// Whether the active gcloud account still yields an access token. Checks at
// start, hourly, and after every action. Every check and action runs gcloud;
// the shell never reads the token.
Ui.Plugin {
  id: plugin

  name: "gcloud-auth"
  // The last check that succeeded, null until one does: { accounts, active, ok, reason }.
  property var auth: null
  property bool failed: false
  // A refresh asked for while a check ran.
  property bool pending: false
  // The check in flight: { accounts, active }.
  property var checking: null
  // Logged out until a check says otherwise.
  readonly property bool loggedIn: auth !== null && auth.ok
  readonly property string icon: loggedIn ? "\u{F015F}" : "\u{F0164}"
  readonly property string status: failed ? "Check failed"
    : !auth ? "Checking…"
    : auth.ok ? "Logged in as " + auth.active
    : auth.active ? "Logged out: " + auth.active
    : "No active account"

  // Always shown: neither state is an alert. Left-click refreshes while logged
  // in, otherwise logs in.
  barIndicator: ({
    label: plugin.icon,
    foreground: plugin.loggedIn ? plugin.shell.palette.leaf : plugin.shell.palette.off,
    action: () => plugin.loggedIn ? plugin.refresh() : plugin.logIn(),
  })
  menuItems: Object.assign({
    "plugins.gcloud-auth": { icon: plugin.icon, label: "gcloud auth" },
    "plugins.gcloud-auth.status": { icon: plugin.icon, label: plugin.status, enabled: false },
  }, plugin.accountItems(), {
    "plugins.gcloud-auth.refresh": { icon: "󰑐", label: "Refresh now", action: () => plugin.refresh() },
    "plugins.gcloud-auth.login": { icon: "\u{F0342}", label: "Log in",
      enabled: !plugin.loggedIn && !login.running, action: () => plugin.logIn() },
  })

  // Items, not a provider, so a root search finds an account.
  function accountItems() {
    const items = {}
    const accounts = plugin.auth ? plugin.auth.accounts : []
    accounts.forEach((account, index) => {
      items["plugins.gcloud-auth." + index] = {
        icon: plugin.shell.menu.radio(account.status === "ACTIVE"),
        label: account.account,
        action: () => plugin.activate(account.account),
      }
    })
    return items
  }

  function refresh() {
    // Not a binding: `running` notifies only after a Process's exited handler.
    if (list.running || token.running) {
      plugin.pending = true
      return
    }
    list.running = true
  }

  function logIn() { login.running = true }

  function activate(account) {
    switcher.command = ["timeout", "30", "gcloud", "config", "set", "account", account]
    switcher.running = true
  }

  // Ends a check. A failed one (null) keeps the last result.
  function finish(next) {
    plugin.failed = next === null
    if (next) {
      if (Model.loggedOut(plugin.auth, next))
        Quickshell.execDetached(["notify-send", "-a", "gcloud auth", "Logged out: " + next.active, next.reason])
      plugin.auth = next
    }
    if (plugin.pending) {
      plugin.pending = false
      plugin.refresh()
    }
  }

  IpcHandler {
    target: "gcloud-auth"

    function refresh(): void { plugin.refresh() }
    function login(): void { plugin.logIn() }
    function status(): string { return plugin.status }
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
    stdout: StdioCollector { id: listOut }
    onExited: {
      const accounts = Model.parseAccounts(listOut.text)
      const active = accounts ? Model.activeAccount(accounts) : ""
      if (!active) {
        plugin.finish(accounts ? { accounts: accounts, active: "", ok: false, reason: "" } : null)
        return
      }
      plugin.checking = { accounts: accounts, active: active }
      token.command = ["timeout", "30", "gcloud", "auth", "print-access-token", "--account=" + active]
      token.running = true
    }
  }

  // No stdout collector: the token is discarded unread.
  Process {
    id: token
    stderr: StdioCollector { id: tokenErr }
    onExited: function (exitCode) {
      const result = Model.token(exitCode, tokenErr.text)
      plugin.finish(result ? Object.assign({}, plugin.checking, result) : null)
    }
  }

  // Opens the browser; gcloud adds the account and makes it active.
  Process {
    id: login
    command: ["timeout", "300", "gcloud", "auth", "login", "--brief"]
    onExited: plugin.refresh()
  }

  Process {
    id: switcher
    onExited: plugin.refresh()
  }
}
