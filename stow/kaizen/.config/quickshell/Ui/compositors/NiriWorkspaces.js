function workspaceState(list) {
  var source = Array.isArray(list) ? list : []
  var workspaces = {}
  var activeByOutput = {}

  for (var index = 0; index < source.length; index++) {
    var workspace = source[index]
    if (!workspace || workspace.id === undefined || workspace.idx === undefined) continue
    workspaces[workspace.id] = { idx: workspace.idx, output: workspace.output }
    if (workspace.is_active) activeByOutput[workspace.output] = workspace.idx
  }

  return { workspaces: workspaces, activeByOutput: activeByOutput }
}

function windowCounts(list) {
  var source = Array.isArray(list) ? list : []
  var counts = {}

  for (var index = 0; index < source.length; index++) {
    var window = source[index]
    if (window && window.workspace_id !== undefined && window.workspace_id !== null)
      counts[window.workspace_id] = (counts[window.workspace_id] || 0) + 1
  }
  return counts
}

function ids(workspaces, output) {
  var result = []
  for (var id in workspaces) {
    if (workspaces[id].output === output) result.push(workspaces[id].idx)
  }
  result.sort(function(left, right) { return left - right })
  return result
}

function occupied(workspaces, counts, output, idx) {
  for (var id in workspaces) {
    var workspace = workspaces[id]
    if (workspace.output === output && workspace.idx === idx && (counts[id] || 0) > 0) return true
  }
  return false
}

function eventResult(state, event) {
  var previous = state || {}
  var next = {
    workspaces: previous.workspaces || {},
    activeByOutput: previous.activeByOutput || {},
    windowCounts: previous.windowCounts || {},
    queryWindows: false,
  }
  var value = event || {}

  if (value.WorkspacesChanged) {
    var workspaces = workspaceState(value.WorkspacesChanged.workspaces)
    next.workspaces = workspaces.workspaces
    next.activeByOutput = workspaces.activeByOutput
    next.queryWindows = true
  } else if (value.WorkspaceActivated) {
    var activated = next.workspaces[value.WorkspaceActivated.id]
    if (activated) {
      next.activeByOutput = Object.assign({}, next.activeByOutput)
      next.activeByOutput[activated.output] = activated.idx
    }
  } else if (value.WindowsChanged) {
    next.windowCounts = windowCounts(value.WindowsChanged.windows)
  } else if (value.WindowOpenedOrChanged || value.WindowClosed || value.WindowLayoutsChanged) {
    next.queryWindows = true
  }

  return next
}
