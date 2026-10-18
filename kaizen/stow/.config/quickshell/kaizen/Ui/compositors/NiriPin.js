// The window of appId in windows, NiriEvents' map; 0 while it has none.
function windowId(windows, appId) {
  for (var id in windows) {
    if (windows[id] && windows[id].app_id === appId) return windows[id].id;
  }
  return 0;
}

// niri has neither an aspect-ratio rule nor sticky windows (FAQ, issue 932),
// so the window id is kept square and moved to each workspace that gains
// focus. requested is the height last asked for, so a height niri will not
// grant is asked for once instead of on every event it provokes; workspaces
// is NiriEvents' map, for the indices actions take. Returns
// {requested, command}, command null when there is nothing to run.
function follow(event, id, workspaces, requested) {
  var value = event || {};
  var none = { requested: requested, command: null };
  if (!id) return none;
  if (value.WorkspaceActivated) {
    var workspace = (workspaces || {})[value.WorkspaceActivated.id];
    if (!value.WorkspaceActivated.focused || !workspace) return none;
    return {
      requested: requested,
      command: [
        "niri",
        "msg",
        "action",
        "move-window-to-workspace",
        "--window-id",
        String(id),
        "--focus",
        "false",
        String(workspace.idx),
      ],
    };
  }
  if (!value.WindowLayoutsChanged) return none;
  var changes = value.WindowLayoutsChanged.changes || [];
  for (var i = 0; i < changes.length; i++) {
    if (changes[i][0] !== id) continue;
    var size = (changes[i][1] || {}).window_size || [];
    if (size[0] === size[1] || size[0] === requested) return none;
    return {
      requested: size[0],
      command: [
        "niri",
        "msg",
        "action",
        "set-window-height",
        "--id",
        String(id),
        String(size[0]),
      ],
    };
  }
  return none;
}
