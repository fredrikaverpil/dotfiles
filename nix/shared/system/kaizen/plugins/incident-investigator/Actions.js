.pragma library
.import "Format.js" as Format

// The palette's rows, a static tree for Ui.MenuOverlay: the focused
// investigation's actions, or the picked set's, then the window's. A row runs
// its action with its arg.
//
// state: current (the selected investigation, or null), picked (the picked
// investigations), deletable and clearable (counts), clearLabel, tags, model,
// effort, tagFilter, projectFilter and projects (those the list names).
function actions(state) {
  var first = state.picked.length >= 2 ? pickedRows(state) : state.current ? itemRows(state.current, state.tags) : []
  return first.length ? first.concat([separator], windowRows(state)) : windowRows(state)
}

var separator = { isSeparator: true, enabled: true }

function row(fields) {
  return Object.assign({
    key: "",
    text: "",
    glyph: "",
    detail: "",
    keys: [],
    enabled: true,
    isSeparator: false,
    hasChildren: false,
    children: [],
    action: "",
    arg: ""
  }, fields)
}

function submenu(fields, children) {
  return row(Object.assign({ hasChildren: true, children: children }, fields))
}

function radio(key, text, on, action, arg) {
  return row({ key: key, text: text, glyph: on ? Format.icons.radioOn : Format.icons.radio, action: action, arg: arg })
}

// Picking the investigation's tag again clears it.
function tagMenu(tags, tag) {
  return submenu({ key: "tag", text: "Tag", glyph: Format.icons.tag, detail: tag }, tags.map(function(each) {
    return radio("tag." + each.name, each.name, each.name === tag, "tag", each.name === tag ? "" : each.name)
  }))
}

// The last answer is the conclusion; a failed or empty run has none.
function answer(item) {
  var answers = item.messages.filter(function(message) { return message.kind === "assistant" })
  return answers.length ? answers[answers.length - 1].text : ""
}

function itemRows(item, tags) {
  var rows = []
  var running = item.status === "running"
  if (item.status === "draft") {
    rows.push(row({ key: "run", text: "Run", glyph: Format.icons.play, action: "run" }))
    rows.push(row({ key: "discard", text: "Discard", glyph: Format.icons.trash, action: "discard" }))
  } else if (running) {
    rows.push(row({ key: "stop", text: "Stop", glyph: Format.icons.stop, action: "stop" }))
  } else {
    rows.push(row({ key: "rerun", text: "Re-run", glyph: Format.icons.refresh, action: "rerun" }))
    if (item.status === "done")
      rows.push(row({ key: "followUp", text: "Follow up", glyph: Format.icons.reply, action: "followUp" }))
  }
  if (item.sessionId && item.claudeConfigDir)
    rows.push(row({ key: "terminal", text: "Terminal", glyph: Format.icons.terminal, action: "terminal" }))
  if (!running && answer(item))
    rows.push(row({ key: "copy", text: "Copy answer", glyph: Format.icons.copy, action: "copy", arg: answer(item) }))
  if (tags.length)
    rows.push(tagMenu(tags, item.tag))
  if (!running && item.status !== "draft")
    rows.push(row({ key: "delete", text: "Delete", glyph: Format.icons.trash, keys: ["Backspace"], action: "delete" }))
  return rows
}

function pickedRows(state) {
  var rows = [
    row({ key: "combine", text: "Combine", glyph: Format.icons.plus, detail: state.picked.length + " investigations", action: "combine" }),
    row({ key: "unpick", text: "Unpick", glyph: Format.icons.close, keys: ["Esc"], action: "unpick" })
  ]
  if (state.deletable)
    rows.push(row({ key: "delete", text: "Delete " + state.deletable, glyph: Format.icons.trash, keys: ["Backspace"], action: "delete" }))
  return rows
}

function windowRows(state) {
  var rows = [row({ key: "new", text: "New investigation", glyph: Format.icons.plus, detail: state.tagFilter ? "tag " + state.tagFilter : "", action: "new" })]
  if (state.clearable)
    rows.push(row({ key: "clear", text: state.clearLabel, glyph: Format.icons.trash, action: "clear" }))
  rows.push(submenu({ key: "model", text: "Model", glyph: Format.icons.model, detail: state.model }, Format.models.map(function(model) {
    return radio("model." + model, model, model === state.model, "model", model)
  })))
  rows.push(submenu({ key: "effort", text: "Effort", glyph: Format.icons.effort, detail: state.effort }, Format.efforts.map(function(effort) {
    return radio("effort." + effort, effort, effort === state.effort, "effort", effort)
  })))
  var filters = []
  if (state.tags.length)
    filters.push(submenu({ key: "filter.tag", text: "Tag", glyph: Format.icons.tag, detail: state.tagFilter }, [radio("filter.tag.", "All", !state.tagFilter, "filterTag", "")].concat(state.tags.map(function(tag) {
      return radio("filter.tag." + tag.name, tag.name, tag.name === state.tagFilter, "filterTag", tag.name)
    }))))
  if (state.projects.length)
    filters.push(submenu({ key: "filter.project", text: "Project", glyph: Format.icons.filter, detail: state.projectFilter.join(", ") }, [radio("filter.project.", "All projects", !state.projectFilter.length, "filterProject", "")].concat(state.projects.map(function(project) {
      var on = state.projectFilter.indexOf(project) >= 0
      return row({ key: "filter.project." + project, text: project, glyph: on ? Format.icons.checkOn : Format.icons.check, action: "filterProject", arg: project })
    }))))
  if (filters.length)
    rows.push(submenu({ key: "filter", text: "Filter", glyph: Format.icons.filter, detail: [state.tagFilter].concat(state.projectFilter).filter(Boolean).join(", ") }, filters))
  return rows
}
