// workspaces and windows are NiriEvents' maps of niri's ids to its objects.

function windowCounts(windows) {
  var counts = {};
  for (var id in windows) {
    var window = windows[id];
    if (
      window &&
      window.workspace_id !== undefined &&
      window.workspace_id !== null
    )
      counts[window.workspace_id] = (counts[window.workspace_id] || 0) + 1;
  }
  return counts;
}

function ids(workspaces, output) {
  var result = [];
  for (var id in workspaces) {
    if (workspaces[id].output === output) result.push(workspaces[id].idx);
  }
  result.sort(function (left, right) {
    return left - right;
  });
  return result;
}

function activeId(workspaces, output) {
  for (var id in workspaces) {
    var workspace = workspaces[id];
    if (workspace.output === output && workspace.is_active)
      return workspace.idx;
  }
  return -1;
}

function occupied(workspaces, counts, output, idx) {
  for (var id in workspaces) {
    var workspace = workspaces[id];
    if (
      workspace.output === output &&
      workspace.idx === idx &&
      (counts[id] || 0) > 0
    )
      return true;
  }
  return false;
}
