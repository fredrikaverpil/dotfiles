// What every backend defines for Compositor.qml to forward: each property
// with its typeof, and each function.
var properties = {
  name: "string",
  releaseExclusiveFocus: "boolean",
  replacesDeadLock: "boolean",
  opensOnFocusedOutput: "boolean",
  floatsInWorkingArea: "boolean",
  workspaceComponent: "string",
  closeWindowAction: "string",
};

var functions = [
  "dpms",
  "closeWindow",
  "screenshot",
  "configFile",
  // Returns chords as Chords.js reads them.
  "readBinds",
  "focusWorkspace",
  "focusApp",
  "focusMonitor",
  "outputs",
  "focusedOutputOn",
  "focusedMonitor",
  "layoutQuery",
  "currentLayout",
  "layoutNames",
  "setLayout",
];

// What a backend may lack, each feature with its names: a function, or a
// component's file name. A backend defines all of a feature's names or none.
var optional = {
  casts: ["castComponent"],
  windowScreenshot: ["screenshotWindow"],
  colorPicker: ["pickColor"],
  camera: ["pinComponent", "moveFloatingWindow"],
  borders: ["borderColors", "borderFile"],
};

function present(backend, key) {
  var value = backend[key];
  return (
    typeof value === "function" || (typeof value === "string" && value !== "")
  );
}

// The contract's names that backend leaves undefined or of another type, and
// the names a feature it defines in part lacks.
function missing(backend) {
  var names = Object.keys(properties).filter(function (key) {
    return typeof backend[key] !== properties[key];
  });
  names = names.concat(
    functions.filter(function (key) {
      return typeof backend[key] !== "function";
    }),
  );
  return Object.keys(optional).reduce(function (names, feature) {
    var keys = optional[feature];
    var absent = keys.filter(function (key) {
      return !present(backend, key);
    });
    return absent.length < keys.length ? names.concat(absent) : names;
  }, names);
}

// Each optional feature, true when backend defines it.
function supports(backend) {
  var result = {};
  Object.keys(optional).forEach(function (feature) {
    result[feature] = optional[feature].every(function (key) {
      return present(backend, key);
    });
  });
  return result;
}
