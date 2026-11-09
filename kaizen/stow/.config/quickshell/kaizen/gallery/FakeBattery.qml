import QtQuick

import "../modules/services/battery/BatteryModel.js" as Model

// The battery service's members the view reads, without UPower.
QtObject {
    id: fake

    // UPower's device state values.
    readonly property var deviceStates: ({
            Charging: 1,
            FullyCharged: 4,
            PendingCharge: 5
        })
    readonly property var scenarios: ({
            "78% on battery": {
                present: true,
                snapshot: {
                    state: 2,
                    fraction: 0.78,
                    rate: 8.4,
                    onBattery: true,
                    timeToEmpty: 11520,
                    timeToFull: 0
                }
            },
            "12% low": {
                present: true,
                snapshot: {
                    state: 2,
                    fraction: 0.12,
                    rate: 9.1,
                    onBattery: true,
                    timeToEmpty: 1440,
                    timeToFull: 0
                }
            },
            "6% critical": {
                present: true,
                snapshot: {
                    state: 2,
                    fraction: 0.06,
                    rate: 9.4,
                    onBattery: true,
                    timeToEmpty: 660,
                    timeToFull: 0
                }
            },
            "Charging": {
                present: true,
                snapshot: {
                    state: 1,
                    fraction: 0.54,
                    rate: 31.6,
                    onBattery: false,
                    timeToEmpty: 0,
                    timeToFull: 3120
                }
            },
            "Holding": {
                present: true,
                snapshot: {
                    state: 5,
                    fraction: 0.8,
                    rate: 0,
                    onBattery: false,
                    timeToEmpty: 0,
                    timeToFull: 0
                }
            },
            "No battery": {
                present: false,
                snapshot: {
                    state: 0,
                    fraction: 0,
                    rate: 0,
                    onBattery: false,
                    timeToEmpty: 0,
                    timeToFull: 0
                }
            }
        })

    readonly property int warnLevel: 20
    readonly property int lowLevel: 10
    property bool present: true
    property var snapshot: scenarios["78% on battery"].snapshot
    readonly property bool onBattery: snapshot.onBattery
    readonly property int startThreshold: 75
    readonly property int endThreshold: 80
    readonly property int cycles: present ? 212 : 0
    property string profile: "balanced"
    property bool hasPerformance: true

    readonly property int percentage: Model.percent(snapshot.fraction)
    readonly property string stateLabel: Model.status(snapshot, deviceStates, endThreshold)
    readonly property string icon: Model.icon(snapshot, deviceStates, endThreshold)
    readonly property string chargeRole: onBattery ? levelRole(percentage) : "fg"
    readonly property string timeRemaining: Model.timeRemaining(snapshot, deviceStates, endThreshold)
    readonly property string rate: present ? Model.formatRate(snapshot.rate) : "--"
    readonly property string energy: present ? Model.formatEnergy(snapshot.fraction * 50.4, 50.4) : "--"
    readonly property string health: present ? Model.formatHealth(true, 94) : "--"
    readonly property string threshold: Model.formatThreshold(startThreshold, endThreshold)

    function levelRole(level) {
        return Model.levelRole(level, warnLevel, lowLevel);
    }

    function refresh() {
    }

    function profiles() {
        return hasPerformance ? Model.profiles : Model.profiles.slice(0, 2);
    }

    function setProfile(name) {
        if (profiles().indexOf(name) < 0)
            return false;
        profile = name;
        return true;
    }
}
