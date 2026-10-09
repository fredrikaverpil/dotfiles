import QtQuick
import QtTest
import "../modules/services/firmware/FirmwareModel.js" as Firmware
import "../modules/services/firmware/Fwupd.js" as Fwupd

TestCase {
    name: "FirmwareModel"

    // `fwupdmgr get-updates --json` on a ThinkPad T14 Gen 6, trimmed.
    readonly property string wily: JSON.stringify({
        Devices: [
            {
                Name: "SKHynix HFS001TFM9X179N",
                DeviceId: "04e17fcf7d3de91da49a163ffe4907855c3648be",
                Plugin: "nvme",
                Vendor: "SK hynix",
                Version: "61720A20",
                Flags: ["internal", "updatable", "require-ac", "supported", "needs-reboot"],
                Problems: null,
                Releases: [
                    {
                        Version: "61730A20",
                        Summary: "SK hynix PCB01_TBG NVMe SSD Firmware for Lenovo PC",
                        Description: "<p>Do Not turn off your computer.</p><p>[Problem fixes] Enhance SSD debuggability</p>",
                        Urgency: "high",
                        AppstreamId: "com.lenovo.PCB01_TBG.firmware"
                    }
                ]
            },
            {
                Name: "UEFI dbx",
                DeviceId: "362301da643102b9f38477387e2193e57abaa590",
                Plugin: "uefi_dbx",
                Vendor: "Microsoft",
                Version: "20250507",
                Flags: ["internal", "updatable", "supported", "needs-reboot"],
                Problems: null,
                Releases: [
                    {
                        Version: "20260707",
                        Summary: "UEFI Secure Boot Forbidden Signature Database",
                        Description: "<p>Signed by the &quot;2023&quot; KEK.</p><ul><li>New Horizon Datasys Inc</li><li>EAZ Solution Inc</li></ul>",
                        Urgency: "medium",
                        AppstreamId: "com.microsoft.dbx.x64-kek2023.firmware"
                    },
                    {
                        Version: "20260402",
                        Urgency: "high"
                    }
                ]
            },
            {
                Name: "TPM",
                DeviceId: "c6a80ac3a22083423992a3cb15018989f37834d6",
                Plugin: "tpm",
                Version: "7.2.3.1",
                Flags: ["internal"],
                Releases: []
            }
        ]
    })

    readonly property var ssd: ({
            backend: "fwupd",
            id: "04e17fcf7d3de91da49a163ffe4907855c3648be",
            name: "SKHynix HFS001TFM9X179N",
            vendor: "SK hynix",
            current: "61720A20",
            version: "61730A20",
            urgency: "high",
            summary: "SK hynix PCB01_TBG NVMe SSD Firmware for Lenovo PC",
            notes: "Do Not turn off your computer.\n[Problem fixes] Enhance SSD debuggability",
            url: "https://fwupd.org/lvfs/devices/com.lenovo.PCB01_TBG.firmware",
            issues: [],
            needsAc: true,
            needsReboot: true,
            command: "fwupdmgr update 04e17fcf7d3de91da49a163ffe4907855c3648be"
        })

    readonly property var dbx: ({
            backend: "fwupd",
            id: "362301da643102b9f38477387e2193e57abaa590",
            name: "UEFI dbx",
            vendor: "Microsoft",
            current: "20250507",
            version: "20260707",
            urgency: "medium",
            summary: "UEFI Secure Boot Forbidden Signature Database",
            notes: "Signed by the \"2023\" KEK.\n• New Horizon Datasys Inc\n• EAZ Solution Inc",
            url: "https://fwupd.org/lvfs/devices/com.microsoft.dbx.x64-kek2023.firmware",
            issues: [],
            needsAc: false,
            needsReboot: true,
            command: "fwupdmgr update 362301da643102b9f38477387e2193e57abaa590"
        })

    function test_fwupd_parse_data() {
        return [
            {
                tag: "devices with releases, newest release",
                text: wily,
                want: {
                    updates: [ssd, dbx],
                    error: ""
                }
            },
            {
                tag: "nothing pending",
                text: '{"Devices":[]}',
                want: {
                    updates: [],
                    error: ""
                }
            },
            {
                tag: "not JSON",
                text: "Failed to connect to daemon",
                want: {
                    updates: [],
                    error: "fwupdmgr: unreadable output"
                }
            },
        ];
    }

    function test_fwupd_parse(data) {
        compare(Fwupd.parse(data.text), data.want);
    }

    function test_backends_data() {
        return [
            {
                tag: "enabled",
                value: "fwupd",
                want: ["fwupd"]
            },
            {
                tag: "unknown dropped",
                value: "system76:fwupd",
                want: ["fwupd"]
            },
            {
                tag: "unset",
                value: undefined,
                want: []
            },
        ];
    }

    function test_backends(data) {
        compare(Firmware.backends(data.value, ["fwupd"]), data.want);
    }

    function test_merge() {
        const results = {
            fwupd: {
                updates: [ssd],
                error: ""
            },
            other: {
                updates: [dbx],
                error: "daemon not running"
            }
        };
        compare(Firmware.merge(["other", "fwupd"], results), {
            updates: [dbx, ssd],
            errors: [
                {
                    backend: "other",
                    error: "daemon not running"
                }
            ]
        });
        compare(Firmware.merge(["fwupd"], {}), {
            updates: [],
            errors: []
        });
    }

    function test_fwupd_release_url_data() {
        return [
            {
                tag: "details URL wins",
                release: {
                    DetailsUrl: "https://example.com/notes",
                    AppstreamId: "com.example.firmware"
                },
                want: "https://example.com/notes"
            },
            {
                tag: "non-https details URL falls back",
                release: {
                    DetailsUrl: "file:///etc/passwd",
                    AppstreamId: "com.example.firmware"
                },
                want: "https://fwupd.org/lvfs/devices/com.example.firmware"
            },
            {
                tag: "LVFS device page",
                release: {
                    AppstreamId: "com.example.firmware"
                },
                want: "https://fwupd.org/lvfs/devices/com.example.firmware"
            },
            {
                tag: "neither",
                release: {},
                want: ""
            },
        ];
    }

    function test_fwupd_release_url(data) {
        verify(Fwupd.releaseUrl(data.release) === data.want, "got " + Fwupd.releaseUrl(data.release));
    }

    function test_order() {
        const low = Object.assign({}, ssd, {
            name: "Camera",
            urgency: "low"
        });
        const critical = Object.assign({}, dbx, {
            urgency: "critical"
        });
        compare(Firmware.order([low, critical, ssd]), [critical, ssd, low]);
    }

    function test_urgency_role_data() {
        return [
            {
                tag: "critical",
                urgency: "critical",
                want: "rose"
            },
            {
                tag: "high",
                urgency: "high",
                want: "rose"
            },
            {
                tag: "medium",
                urgency: "medium",
                want: "wood"
            },
            {
                tag: "low",
                urgency: "low",
                want: "off"
            },
            {
                tag: "unset",
                urgency: "",
                want: "off"
            },
        ];
    }

    function test_urgency_role(data) {
        verify(Firmware.urgencyRole(data.urgency) === data.want);
    }

    function test_detail_data() {
        return [
            {
                tag: "AC and reboot",
                update: ssd,
                want: "61720A20 → 61730A20 · needs AC · reboot"
            },
            {
                tag: "reboot only",
                update: dbx,
                want: "20250507 → 20260707 · reboot"
            },
            {
                tag: "CVEs only",
                update: Object.assign({}, ssd, {
                    issues: ["CVE-2026-20760", "CVE-2025-35973", "LEN-12345"]
                }),
                want: "61720A20 → 61730A20 · 2 CVEs · needs AC · reboot"
            },
            {
                tag: "one CVE",
                update: Object.assign({}, ssd, {
                    issues: ["CVE-2026-20760"]
                }),
                want: "61720A20 → 61730A20 · 1 CVE · needs AC · reboot"
            },
        ];
    }

    function test_detail(data) {
        verify(Firmware.detail(data.update) === data.want, "got " + Firmware.detail(data.update));
    }
}
