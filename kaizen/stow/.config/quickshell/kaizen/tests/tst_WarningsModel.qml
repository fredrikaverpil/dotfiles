import QtQuick
import QtTest
import "../modules/services/weather/WarningsModel.js" as Warnings
import "../modules/services/weather/PlacesModel.js" as Places

TestCase {
    name: "WarningsModel"

    // A square from (west, south) to (east, north), as GeoJSON rings.
    function square(west, south, east, north) {
        return [[west, south], [east, south], [east, north], [west, north], [west, south]];
    }

    // Göteborg sits inside the 11–13 E, 57–58 N square.
    readonly property var land: ({
            type: "Polygon",
            coordinates: [square(11, 57, 13, 58)]
        })

    function area(level, start, end, geometry, sea) {
        return {
            warningLevel: {
                en: level.charAt(0) + level.slice(1).toLowerCase(),
                code: level
            },
            eventDescription: {
                en: "Wind",
                code: "WIND"
            },
            areaName: {
                en: "Västra Götaland"
            },
            approximateStart: start,
            approximateEnd: end,
            area: {
                type: "Feature",
                properties: sea ? {
                    code: "SWE_SEA_DISTRICTS"
                } : null,
                geometry: geometry
            }
        };
    }

    function response(areas) {
        return JSON.stringify([
            {
                event: {
                    en: "Wind",
                    code: "WIND"
                },
                warningAreas: areas
            }
        ]);
    }

    readonly property string now: "2026-11-12T12:00:00.000Z"

    function test_contains_data() {
        return [
            {
                tag: "inside a polygon",
                geometry: land,
                want: true
            },
            {
                tag: "outside a polygon",
                geometry: {
                    type: "Polygon",
                    coordinates: [square(17, 59, 19, 60)]
                },
                want: false
            },
            {
                tag: "in a hole",
                geometry: {
                    type: "Polygon",
                    coordinates: [square(11, 57, 13, 58), square(11.5, 57.5, 12.5, 57.9)]
                },
                want: false
            },
            {
                tag: "in a multipolygon's second part",
                geometry: {
                    type: "MultiPolygon",
                    coordinates: [[square(17, 59, 19, 60)], [square(11, 57, 13, 58)]]
                },
                want: true
            },
            {
                tag: "no geometry",
                geometry: null,
                want: false
            },
        ];
    }

    function test_contains(data) {
        verify(Warnings.contains(data.geometry, 57.71, 11.97) === data.want);
    }

    function test_warnings_at_data() {
        const yellow = {
            level: "wood",
            icon: Warnings.eventGlyph("WIND"),
            severity: "Yellow",
            event: "Wind",
            area: "Västra Götaland",
            start: Date.parse("2026-11-12T10:00:00.000Z"),
            end: Date.parse("2026-11-12T20:00:00.000Z")
        };
        return [
            {
                tag: "yellow under way",
                areas: [area("YELLOW", "2026-11-12T10:00:00.000Z", "2026-11-12T20:00:00.000Z", land, false)],
                want: [yellow]
            },
            {
                tag: "orange and red are rose",
                areas: [area("ORANGE", "2026-11-12T10:00:00.000Z", null, land, false)],
                want: [
                    {
                        level: "rose",
                        icon: Warnings.eventGlyph("WIND"),
                        severity: "Orange",
                        event: "Wind",
                        area: "Västra Götaland",
                        start: Date.parse("2026-11-12T10:00:00.000Z"),
                        end: null
                    }
                ]
            },
            {
                tag: "message left out",
                areas: [area("MESSAGE", "2026-05-25T22:00:00.000Z", null, land, false)],
                want: []
            },
            {
                tag: "sea district left out",
                areas: [area("YELLOW", "2026-11-12T10:00:00.000Z", null, land, true)],
                want: []
            },
            {
                tag: "starts after the next 12 hours",
                areas: [area("YELLOW", "2026-11-13T00:00:00.000Z", null, land, false)],
                want: []
            },
            {
                tag: "already over",
                areas: [area("RED", "2026-11-12T06:00:00.000Z", "2026-11-12T11:00:00.000Z", land, false)],
                want: []
            },
            {
                tag: "elsewhere",
                areas: [area("RED", "2026-11-12T10:00:00.000Z", null, {
                        type: "Polygon",
                        coordinates: [square(17, 59, 19, 60)]
                    }, false)],
                want: []
            },
            {
                tag: "worst first",
                areas: [area("YELLOW", "2026-11-12T10:00:00.000Z", "2026-11-12T20:00:00.000Z", land, false), area("RED", "2026-11-12T14:00:00.000Z", null, land, false)],
                want: [
                    {
                        level: "rose",
                        icon: Warnings.eventGlyph("WIND"),
                        severity: "Red",
                        event: "Wind",
                        area: "Västra Götaland",
                        start: Date.parse("2026-11-12T14:00:00.000Z"),
                        end: null
                    },
                    yellow]
            },
        ];
    }

    function test_warnings_at(data) {
        const got = Warnings.warningsAt(response(data.areas), 57.71, 11.97, new Date(now));

        compare(got, data.want);
    }

    function test_warnings_at_rejects_what_does_not_read() {
        verify(Warnings.warningsAt("<html>", 57.71, 11.97, new Date(now)) === null);
        verify(Warnings.warningsAt("{}", 57.71, 11.97, new Date(now)) === null);
    }

    function test_worst_data() {
        return [
            {
                tag: "none",
                a: "",
                b: "",
                want: ""
            },
            {
                tag: "wood over none",
                a: "",
                b: "wood",
                want: "wood"
            },
            {
                tag: "rose over wood",
                a: "rose",
                b: "wood",
                want: "rose"
            },
        ];
    }

    function test_worst(data) {
        verify(Warnings.worst(data.a, data.b) === data.want);
    }

    function test_event_glyph_data() {
        return [
            {
                tag: "wind",
                code: "WIND",
                want: Warnings.EVENT_GLYPHS.WIND
            },
            {
                tag: "mountain wind as wind",
                code: "WIND_MOUNTAINS",
                want: Warnings.EVENT_GLYPHS.WIND
            },
            {
                tag: "flooding",
                code: "FLOODING",
                want: Warnings.EVENT_GLYPHS.FLOODING
            },
            {
                tag: "unknown",
                code: "VOLCANO",
                want: Warnings.ALERT_GLYPH
            },
            {
                tag: "missing",
                code: undefined,
                want: Warnings.ALERT_GLYPH
            },
        ];
    }

    function test_event_glyph(data) {
        verify(Warnings.eventGlyph(data.code) === data.want);
    }

    function test_glyphs_keep_one_per_icon_at_its_worst_level_worst_first() {
        const alerts = [
            {
                level: "wood",
                icon: "T",
                text: "Risk of thunder"
            },
            {
                level: "wood",
                icon: "W",
                text: "Yellow warning: wind"
            },
            {
                level: "rose",
                icon: "W",
                text: "Gale, gusts up to 27 m/s"
            },
            {
                level: "wood",
                icon: "R",
                text: "Yellow warning: rain"
            }
        ];

        const got = Warnings.glyphs(alerts);

        compare(got, [
            {
                icon: "W",
                level: "rose"
            },
            {
                icon: "T",
                level: "wood"
            },
            {
                icon: "R",
                level: "wood"
            }
        ]);
    }

    function test_country_at_data() {
        return [
            {
                tag: "home",
                latitude: 57.71,
                longitude: 11.97,
                want: "Sweden"
            },
            {
                tag: "abroad",
                latitude: 59.91,
                longitude: 10.75,
                want: "Norway"
            },
            {
                tag: "an unlisted spot",
                latitude: 57.7,
                longitude: 11.9,
                want: ""
            },
        ];
    }

    function test_country_at(data) {
        verify(Places.countryAt(data.latitude, data.longitude) === data.want);
    }
}
