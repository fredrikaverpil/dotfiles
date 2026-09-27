import QtQuick

import qs.Ui as Ui

// Events from dcal (dankcalendar), which default.nix runs.
Ui.Plugin {
  id: plugin

  name: "calendar"
  menuItems: ({
    "settings.calendar": { icon: "󰃭", label: "Calendar" },
    "settings.calendar.panel": { icon: "󰕮", label: "Calendar panel", action: () => calendarPanel.open() },
    "settings.calendar.refresh": { icon: "󰑐", label: "Refresh", action: () => calendarService.refresh() },
  })
  barButton: Component {
    Ui.BarButton {
      shell: plugin.shell
      label: "󰃭"
      onActivated: calendarPanel.toggle()
    }
  }

  Service {
    id: calendarService
  }

  Panel {
    id: calendarPanel
    shell: plugin.shell
    service: calendarService
  }
}
