// What every backend defines for Compositor.qml to forward: each property
// with its typeof, and each function.
var properties = {
  name: "string",
  releaseExclusiveFocus: "boolean",
  replacesDeadLock: "boolean",
  opensOnFocusedOutput: "boolean",
  floatsInWorkingArea: "boolean",
  workspaceComponent: "string",
  castComponent: "string",
  borderFile: "string",
  closeWindowAction: "string",
};

var functions = [
  "borderColors",
  "dpms",
  "closeWindow",
  "screenshot",
  "pickColor",
  "configFile",
  // Returns chords as Chords.js reads them.
  "readBinds",
  "focusWorkspace",
  "focusApp",
  "focusMonitor",
  "outputs",
  "focusedOutputOn",
  "focusedMonitor",
  "events",
  "moveFloatingWindow",
  "pinWindow",
  "layoutQuery",
  "currentLayout",
  "layoutNames",
  "setLayout",
];

// The contract's names that backend leaves undefined or of another type.
function missing(backend) {
  var names = Object.keys(properties).filter(function (key) {
    return typeof backend[key] !== properties[key];
  });
  return names.concat(
    functions.filter(function (key) {
      return typeof backend[key] !== "function";
    }),
  );
}
