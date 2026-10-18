// niri's state as its event stream tells it: a full list first, then single
// changes. state is {workspaces, windows, casts}; workspaces and windows map
// niri's ids to its objects. A family the event leaves alone keeps its object,
// and focus, layout and urgency changes leave the state as it was.
function eventResult(state, event) {
  var value = event || {};
  var workspaces = workspacesResult(state.workspaces, value);
  var windows = windowsResult(state.windows, value);
  var casts = castsResult(state.casts, value);
  if (
    workspaces === state.workspaces &&
    windows === state.windows &&
    casts === state.casts
  )
    return state;
  return { workspaces: workspaces, windows: windows, casts: casts };
}

function byId(list) {
  var result = {};
  (Array.isArray(list) ? list : []).forEach(function (item) {
    if (item && item.id !== undefined) result[item.id] = item;
  });
  return result;
}

function workspacesResult(workspaces, event) {
  if (event.WorkspacesChanged) return byId(event.WorkspacesChanged.workspaces);
  if (!event.WorkspaceActivated) return workspaces;
  var activated = workspaces[event.WorkspaceActivated.id];
  if (!activated) return workspaces;
  var focused = event.WorkspaceActivated.focused;
  var result = {};
  for (var id in workspaces) {
    var workspace = workspaces[id];
    var active =
      workspace.output === activated.output
        ? workspace === activated
        : workspace.is_active;
    result[id] = Object.assign({}, workspace, {
      is_active: active,
      is_focused: focused ? workspace === activated : workspace.is_focused,
    });
  }
  return result;
}

function windowsResult(windows, event) {
  if (event.WindowsChanged) return byId(event.WindowsChanged.windows);
  var result;
  if (event.WindowOpenedOrChanged) {
    var window = event.WindowOpenedOrChanged.window;
    if (!window) return windows;
    result = Object.assign({}, windows);
    result[window.id] = window;
    return result;
  }
  if (event.WindowClosed && event.WindowClosed.id in windows) {
    result = Object.assign({}, windows);
    delete result[event.WindowClosed.id];
    return result;
  }
  return windows;
}

function castsResult(casts, event) {
  if (event.CastsChanged) return event.CastsChanged.casts || [];
  if (event.CastStartedOrChanged) {
    var cast = event.CastStartedOrChanged.cast;
    return casts
      .filter(function (other) {
        return other.stream_id !== cast.stream_id;
      })
      .concat([cast]);
  }
  if (event.CastStopped)
    return casts.filter(function (other) {
      return other.stream_id !== event.CastStopped.stream_id;
    });
  return casts;
}
