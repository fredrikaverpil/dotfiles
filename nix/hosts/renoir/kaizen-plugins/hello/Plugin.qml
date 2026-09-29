import Quickshell
import qs.Ui as Ui

// The minimal plugin: a launcher node and one action.
Ui.Plugin {
  name: "hello"
  menuItems: ({
    "plugins.hello": { icon: "󰞅", label: "Hello" },
    "plugins.hello.greet": { icon: "󰍡", label: "Say hello",
      action: () => Quickshell.execDetached(["notify-send", "Hello", "Hello from a kaizen plugin"]) },
  })
}
