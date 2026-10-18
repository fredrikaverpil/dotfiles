// Stands in when KAIZEN_COMPOSITOR names no compositor, so the shell still runs
// and locks. Every command fails, and every query answers with nothing.
var name = "";

var releaseExclusiveFocus = false;
var replacesDeadLock = true;
var opensOnFocusedOutput = true;
var floatsInWorkingArea = true;
// No source loads.
var workspaceComponent = "";
var castComponent = "";
var borderFile = "";
var closeWindowAction = "";

var fail = ["false"];

function borderColors(palette) {
  return "";
}

function dpms(on) {
  return fail;
}

function closeWindow() {
  return fail;
}

function screenshot(mode, path) {
  return fail;
}

function pickColor() {
  return fail;
}

function configFile(home, getenv) {
  return "";
}

function readBinds(file, home, read) {
  return [];
}

function focusWorkspace(id, output) {
  return fail;
}

function focusApp(pattern) {
  return fail;
}

function focusMonitor(output) {
  return fail;
}

function outputs() {
  return fail;
}

function focusedOutputOn(output) {
  return fail;
}

function focusedMonitor(raw) {
  return null;
}

function events() {
  return fail;
}

function moveFloatingWindow(id, x, y) {
  return fail;
}

function pinWindow(raw, appId, state) {
  return { id: state.id, requested: state.requested, spaces: state.spaces };
}

function layoutQuery() {
  return fail;
}

function currentLayout(raw) {
  return -1;
}

function layoutNames(raw) {
  return [];
}

function setLayout(index, current, count) {
  return fail;
}
