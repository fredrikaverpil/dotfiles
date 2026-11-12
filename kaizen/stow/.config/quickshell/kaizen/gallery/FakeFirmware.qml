import QtQuick

import "../modules/services/firmware/FirmwareModel.js" as Model

// The firmware service's members the view reads, without fwupdmgr.
QtObject {
    id: fake

    readonly property real checked: new Date(2026, 10, 12, 14, 2).getTime()
    readonly property var system: ({
            backend: "fwupd",
            id: "6e1d2a8b0c3f4e5d6a7b8c9d0e1f2a3b4c5d6e7f",
            name: "System Firmware",
            vendor: "Lenovo",
            current: "0.1.40",
            version: "0.1.42",
            urgency: "high",
            summary: "Lenovo ThinkPad X1 Carbon Gen 13 System Firmware",
            notes: "Lenovo ThinkPad X1 Carbon Gen 13 System Firmware\n• Security fixes for the SMM handler.\n• Fixes a fan that kept spinning after resume.",
            url: "https://pcsupport.lenovo.com/downloads/ds572881",
            issues: ["CVE-2026-31201", "CVE-2026-31202", "CVE-2026-31277", "LEN-189001"],
            needsAc: true,
            needsReboot: true,
            command: "fwupdmgr update 6e1d2a8b0c3f4e5d6a7b8c9d0e1f2a3b4c5d6e7f"
        })
    readonly property var dbx: ({
            backend: "fwupd",
            id: "362301da643102b9f38477387e2193e57abaa590",
            name: "UEFI dbx",
            vendor: "Linux Foundation",
            current: "371",
            version: "509",
            urgency: "critical",
            summary: "UEFI Secure Boot Forbidden Signature Database",
            notes: "This updates the dbx to the latest release from Microsoft which adds insecure versions of grub and shim to the list of forbidden signatures due to multiple discovered security updates.",
            url: "https://fwupd.org/lvfs/devices/org.linuxfoundation.dbx.x64.firmware",
            issues: ["CVE-2023-24932", "CVE-2024-7344"],
            needsAc: false,
            needsReboot: true,
            command: "fwupdmgr update 362301da643102b9f38477387e2193e57abaa590"
        })
    readonly property var fingerprint: ({
            backend: "fwupd",
            id: "a1b2c3d4e5f60718293a4b5c6d7e8f9012345678",
            name: "Prometheus IOTA Config",
            vendor: "Synaptics",
            current: "0022",
            version: "0027",
            urgency: "medium",
            summary: "Fingerprint reader configuration",
            notes: "Improves matching on dry fingers.",
            url: "",
            issues: [],
            needsAc: false,
            needsReboot: false,
            command: "fwupdmgr update a1b2c3d4e5f60718293a4b5c6d7e8f9012345678"
        })
    readonly property var scenarios: ({
            "Up to date": {
                backends: ["fwupd"],
                checking: false,
                lastChecked: checked,
                updates: [],
                errors: []
            },
            "One pending": {
                backends: ["fwupd"],
                checking: false,
                lastChecked: checked,
                updates: [fingerprint],
                errors: []
            },
            "Several": {
                backends: ["fwupd"],
                checking: false,
                lastChecked: checked,
                updates: Model.order([fingerprint, system, dbx]),
                errors: []
            },
            "Checking": {
                backends: ["fwupd"],
                checking: true,
                lastChecked: 0,
                updates: [],
                errors: []
            },
            "Check failed": {
                backends: ["fwupd"],
                checking: false,
                lastChecked: checked,
                updates: [],
                errors: [
                    {
                        backend: "fwupd",
                        error: "Failed to connect to daemon: Error calling StartServiceByName for org.freedesktop.fwupd: Timeout was reached"
                    }
                ]
            },
            "No backend": {
                backends: [],
                checking: false,
                lastChecked: 0,
                updates: [],
                errors: []
            }
        })

    property var backends: ["fwupd"]
    property bool checking: false
    property real lastChecked: checked
    property var updates: []
    property var errors: []

    function refresh() {
    }

    function copyCommand(id) {
        return updates.some(update => update.id === id);
    }

    // Opens nothing from the gallery.
    function openPage(id) {
        return false;
    }
}
