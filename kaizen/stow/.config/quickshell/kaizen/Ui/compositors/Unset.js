// Stands in when no single compositor's socket variable is set, so the shell
// still runs and locks. Every command fails, every query answers with nothing, and no
// optional feature is defined.
var name = "";

var releaseExclusiveFocus = false;
var replacesDeadLock = true;
var opensOnFocusedOutput = true;
var floatsInWorkingArea = true;
var placesBackdrop = false;
// No source loads.
var eventsComponent = "";
var workspaceComponent = "";
var closeWindowAction = "";

var fail = ["false"];

function dpms(on) {
  return fail;
}

function closeWindow() {
  return fail;
}

function screenshot(path) {
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
