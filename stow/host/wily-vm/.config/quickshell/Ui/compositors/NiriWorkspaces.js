function workspaceState(list, previous) {
  var source = Array.isArray(list) ? list : []
  var ids = []
  var idxById = {}
  var focusedId = previous === undefined ? -1 : previous

  for (var index = 0; index < source.length; index++) {
    var workspace = source[index]
    if (!workspace || workspace.id === undefined || workspace.idx === undefined) continue
    idxById[workspace.id] = workspace.idx
    ids.push(workspace.idx)
    if (workspace.is_focused) focusedId = workspace.idx
  }

  ids.sort(function(left, right) { return left - right })
  return { ids: ids, idxById: idxById, focusedId: focusedId }
}

function windowCounts(list, idxById) {
  var source = Array.isArray(list) ? list : []
  var counts = {}
  var ids = idxById || {}

  for (var index = 0; index < source.length; index++) {
    var window = source[index]
    if (!window) continue
    var workspaceIndex = ids[window.workspace_id]
    if (workspaceIndex !== undefined) counts[workspaceIndex] = (counts[workspaceIndex] || 0) + 1
  }
  return counts
}

function eventResult(state, event) {
  var previous = state || {}
  var next = {
    ids: previous.ids || [],
    idxById: previous.idxById || {},
    focusedId: previous.focusedId === undefined ? -1 : previous.focusedId,
    windowCounts: previous.windowCounts || {},
    queryWindows: false,
  }
  var value = event || {}

  if (value.WorkspacesChanged) {
    var workspaces = workspaceState(value.WorkspacesChanged.workspaces, next.focusedId)
    next.ids = workspaces.ids
    next.idxById = workspaces.idxById
    next.focusedId = workspaces.focusedId
    next.queryWindows = true
  } else if (value.WorkspaceActivated) {
    var activated = value.WorkspaceActivated
    var idx = next.idxById[activated.id]
    if (activated.focused && idx !== undefined) next.focusedId = idx
  } else if (value.WindowsChanged) {
    next.windowCounts = windowCounts(value.WindowsChanged.windows, next.idxById)
  } else if (value.WindowOpenedOrChanged || value.WindowClosed || value.WindowLayoutsChanged) {
    next.queryWindows = true
  }

  return next
}
