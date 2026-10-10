import "../../Ui" as Ui

// Events from dcal (dankcalendar), which default.nix runs.
Ui.Plugin {
    id: plugin

    name: "calendar"
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
    }

    Panel {
        id: calendarPanel
        shell: plugin.shell
        service: calendarService
    }
}
