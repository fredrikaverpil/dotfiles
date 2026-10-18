// list is a workspaces snapshot: each workspace's output, 1-based index,
// active state and window_count.

function onOutput(list, output) {
  return (Array.isArray(list) ? list : []).filter(function (workspace) {
    return workspace && workspace.output === output;
  });
}

function ids(list, output) {
  return onOutput(list, output)
    .map(function (workspace) {
      return workspace.index;
    })
    .sort(function (left, right) {
      return left - right;
    });
}

function activeId(list, output) {
  var active = onOutput(list, output).filter(function (workspace) {
    return workspace.active;
  })[0];
  return active ? active.index : -1;
}

function occupied(list, output, idx) {
  return onOutput(list, output).some(function (workspace) {
    return workspace.index === idx && workspace.window_count > 0;
  });
}
