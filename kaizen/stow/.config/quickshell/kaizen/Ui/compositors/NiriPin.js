// niri has neither an aspect-ratio rule nor sticky windows (FAQ, issue 932),
// so the window of appId is kept square and moved to each workspace that gains
// focus. state is {id, requested, spaces}: the requested height is remembered
// so a height niri will not grant is asked for once instead of on every event
// it provokes, and spaces maps workspace ids to the indices actions take.
function follow(raw, appId, state) {
  var event;
  try {
    event = JSON.parse(String(raw || ""));
  } catch (error) {
    return held(state);
  }
  if (event.WindowsChanged) {
    var match = (event.WindowsChanged.windows || []).filter(function (window) {
      return window && window.app_id === appId;
    })[0];
    return { id: match ? match.id : 0, requested: 0, spaces: state.spaces };
  }
  if (event.WindowOpenedOrChanged) {
    var opened = event.WindowOpenedOrChanged.window;
    if (!opened || opened.app_id !== appId) return held(state);
    return { id: opened.id, requested: 0, spaces: state.spaces };
  }
  if (event.WindowClosed) {
    return event.WindowClosed.id === state.id
      ? { id: 0, requested: 0, spaces: state.spaces }
      : held(state);
  }
  if (event.WorkspacesChanged) {
    var spaces = {};
    var list = event.WorkspacesChanged.workspaces || [];
    for (var space = 0; space < list.length; space++)
      spaces[list[space].id] = list[space].idx;
    return { id: state.id, requested: state.requested, spaces: spaces };
  }
  if (event.WorkspaceActivated) {
    var idx = (state.spaces || {})[event.WorkspaceActivated.id];
    if (!state.id || !event.WorkspaceActivated.focused || idx === undefined)
      return held(state);
    return command(state, [
      "niri",
      "msg",
      "action",
      "move-window-to-workspace",
      "--window-id",
      String(state.id),
      "--focus",
      "false",
      String(idx),
    ]);
  }
  if (!event.WindowLayoutsChanged || !state.id) return held(state);
  var changes = event.WindowLayoutsChanged.changes || [];
  for (var i = 0; i < changes.length; i++) {
    if (changes[i][0] !== state.id) continue;
    var size = (changes[i][1] || {}).window_size || [];
    if (size[0] === size[1] || size[0] === state.requested) return held(state);
    return command({ id: state.id, requested: size[0], spaces: state.spaces }, [
      "niri",
      "msg",
      "action",
      "set-window-height",
      "--id",
      String(state.id),
      String(size[0]),
    ]);
  }
  return held(state);
}

// The state without the command of the event that produced it, so an unchanged
// state is never mistaken for a new one to run.
function held(state) {
  return { id: state.id, requested: state.requested, spaces: state.spaces };
}

function command(state, argv) {
  return {
    id: state.id,
    requested: state.requested,
    spaces: state.spaces,
    command: argv,
  };
}
