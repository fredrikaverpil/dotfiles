import qs.Ui as Ui

// Events from dcal (dux-calendar), which kaizen-dcal.service runs.
Ui.Plugin {
    id: plugin

    menuItems: ({
            "plugins.calendar": {
                icon: "󰃭",
                label: "Calendar"
            },
            "plugins.calendar.panel": {
                icon: "󰕮",
                label: "Calendar panel",
                action: () => calendarPanel.open()
            },
            "plugins.calendar.open": {
                icon: "󰃭",
                label: "Open calendar…",
                action: () => calendarPanel.openApp()
            },
            "plugins.calendar.refresh": {
                icon: "󰑐",
                label: "Refresh",
                action: () => calendarService.refresh()
            }
        })
    barActions: ({
            date: () => calendarPanel.toggle()
        })

    Service {
        id: calendarService
        config: plugin.config
    }

    Panel {
        id: calendarPanel
        shell: plugin.shell
        service: calendarService
    }
}
