import QtQuick
import Quickshell
import Quickshell.Io

import "../../../Ui" as Ui
import "../../services/weather/WeatherModel.js" as Model

Ui.Panel {
    id: root

    required property var service

    cardWidth: view.cardWidth
    cardHeight: view.cardHeight
    keyNavigation: view.keyNavigation

    onShownChanged: if (shown)
        root.service.refreshIfExpired()

    function openForecast() {
        Quickshell.execDetached(["xdg-open", Model.yrUrl(root.service.latitude, root.service.longitude)]);
        root.close();
    }

    IpcHandler {
        target: "weather"

        function open(): void {
            root.open();
        }
        function close(): void {
            root.close();
        }
        function toggle(): void {
            root.toggle();
        }
        function refresh(): void {
            root.service.refresh();
        }
        function setLocation(latitude: real, longitude: real, name: string): string {
            return root.service.setLocation(latitude, longitude, name) ? "ok" : "invalid";
        }
        function home(): void {
            root.service.resetLocation();
        }
        function status(): string {
            return JSON.stringify({
                place: root.service.place,
                latitude: root.service.latitude,
                longitude: root.service.longitude,
                temperature: root.service.temperature,
                condition: root.service.condition,
                days: root.service.days.length,
                outlook: root.service.outlook,
                country: root.service.country,
                warnings: root.service.warnings,
                warningLevel: root.service.warningLevel,
                pollMinutes: root.service.pollMinutes,
                updatedAt: root.service.updatedAt ? root.service.updatedAt.toISOString() : null,
                expiresAt: root.service.expiresAt ? root.service.expiresAt.toISOString() : null
            });
        }
    }

    View {
        id: view
        shell: root.shell
        service: root.service
        onForecastRequested: root.openForecast()
        // The launcher claims focus and closes this panel.
        onLocationRequested: root.shell.menu.open("settings.weather.location")
    }
}
