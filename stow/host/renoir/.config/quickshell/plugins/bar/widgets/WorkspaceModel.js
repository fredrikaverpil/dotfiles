function workspaceIds(live, defaults) {
  var ids = (defaults || [1, 2, 3, 4, 5]).slice()
  var source = Array.isArray(live) ? live : []

  for (var index = 0; index < source.length; index++) {
    var id = source[index]
    if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
  }

  ids.sort(function(left, right) { return left - right })
  return ids
}
