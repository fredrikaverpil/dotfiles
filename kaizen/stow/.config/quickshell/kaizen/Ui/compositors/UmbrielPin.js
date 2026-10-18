// The window rule for appId pins it and fixes its size, so only its id is
// followed, from each windows snapshot; 0 while it has none.
function windowId(raw, appId, id) {
  var event;
  try {
    event = JSON.parse(String(raw || ""));
  } catch (error) {
    return id;
  }
  if (!event || event.event !== "windows" || !Array.isArray(event.data))
    return id;
  var match = event.data.filter(function (window) {
    return window && window.app_id === appId;
  })[0];
  return match ? match.id : 0;
}
