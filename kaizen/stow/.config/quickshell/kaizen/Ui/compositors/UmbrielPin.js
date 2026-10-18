// The window rule for appId pins it and fixes its size, so only its id is
// followed, from windows, UmbrielEvents' snapshot; 0 while it has none.
function windowId(windows, appId) {
  var match = (Array.isArray(windows) ? windows : []).filter(function (window) {
    return window && window.app_id === appId;
  })[0];
  return match ? match.id : 0;
}
