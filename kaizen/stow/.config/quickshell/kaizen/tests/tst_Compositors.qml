import QtQuick
import QtTest
import "../Ui/compositors/Contract.js" as Contract
import "../Ui/compositors/Niri.js" as Niri
import "../Ui/compositors/Umbriel.js" as Umbriel
import "../Ui/compositors/Unset.js" as Unset

TestCase {
    name: "Compositors"

    // A file's text, or null when it cannot be read; qml-test allows local reads.
    function read(path) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + path, false);
        xhr.send();
        return xhr.status === 200 || xhr.status === 0 ? xhr.responseText : null;
    }

    function configPath(relative) {
        return String(Qt.resolvedUrl("../../../" + relative)).replace(/^file:\/\//, "");
    }

    function test_backend_defines_the_contract_data() {
        return [
            {
                tag: "niri",
                name: "niri",
                backend: Niri
            },
            {
                tag: "umbriel",
                name: "umbriel",
                backend: Umbriel
            },
            {
                tag: "unset",
                name: "",
                backend: Unset,
                supported: false
            },
        ];
    }

    function test_backend_defines_the_contract(data) {
        compare(Contract.missing(data.backend), []);
        verify(data.backend.name === data.name);
        const want = {};
        Object.keys(Contract.optional).forEach(feature => want[feature] = data.supported !== false);
        compare(Contract.supports(data.backend), want);
    }

    function test_missing_names_what_a_feature_lacks() {
        const backend = Object.assign({}, Niri, {
            pinComponent: ""
        });
        compare(Contract.missing(backend), ["pinComponent"]);
        verify(Contract.supports(backend).camera === false);
    }

    function test_missing_names_what_a_backend_lacks() {
        const backend = {
            name: 1,
            dpms: "niri"
        };
        compare(Contract.missing(backend), Object.keys(Contract.properties).concat(Contract.functions));
    }

    function test_kaizen_configs_declare_the_same_binds() {
        const home = "/nonexistent";
        const niri = Niri.readBinds(configPath("niri/kaizen.kdl"), home, read);
        const umbriel = Umbriel.readBinds(configPath("umbriel/kaizen.toml"), home, read);
        verify(niri.length > 0);
        compare(umbriel, niri);
    }
}
