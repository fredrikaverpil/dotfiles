import QtQuick
import QtTest
import "../Ui/compositors/Contract.js" as Contract
import "../Ui/compositors/Niri.js" as Niri
import "../Ui/compositors/Umbriel.js" as Umbriel

TestCase {
    name: "Compositors"

    function test_backend_defines_the_contract_data() {
        return [
            {
                tag: "niri",
                backend: Niri
            },
            {
                tag: "umbriel",
                backend: Umbriel
            },
        ];
    }

    function test_backend_defines_the_contract(data) {
        compare(Contract.missing(data.backend), []);
        verify(data.backend.name === data.tag);
    }

    function test_missing_names_what_a_backend_lacks() {
        const backend = {
            name: 1,
            dpms: "niri"
        };
        compare(Contract.missing(backend), Object.keys(Contract.properties).concat(Contract.functions));
    }
}
