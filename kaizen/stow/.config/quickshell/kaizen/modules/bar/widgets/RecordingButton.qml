import QtQuick

import "../../services/recording/RecordingModel.js" as RecordingModel
import "../../../Ui" as Ui

// The recording indicator: the countdown or elapsed time, shown while busy.
Ui.BarButton {
    id: button

    required property var service

    visible: button.service.busy
    implicitWidth: visible ? 76 * button.shell.textScale : 0
    foreground: button.service.paused ? button.shell.palette.off : button.shell.palette.rose
    label: "󰑊 " + (button.service.countdown > 0 ? button.service.countdown : RecordingModel.elapsed(button.service.seconds))
}
