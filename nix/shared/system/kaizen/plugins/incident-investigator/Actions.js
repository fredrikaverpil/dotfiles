.pragma library
.import "Format.js" as Format

// The palette's rows, one static tree per scope for Ui.MenuOverlay. A row runs
// its action with its arg on its ids; a key shows only where it runs the row.
//
// state: listed (the investigations the list shows), picked (the picked ones),
// clearable (a count), clearLabel, tags, tagCounts (every investigation's,
// by tag name, "" for all), model, effort, tagFilter, projectFilter and
// projects (those the list names).

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
    arg: "",
    ids: []
  }, fields)
}

function submenu(fields, children) {
  return row(Object.assign({ hasChildren: true, children: children }, fields))
}

function radio(key, text, on, action, arg) {
  return row({ key: key, text: text, glyph: on ? Format.icons.radioOn : Format.icons.radio, action: action, arg: arg })
}

function check(key, text, on, action, arg) {
  return row({ key: key, text: text, glyph: on ? Format.icons.checkOn : Format.icons.check, action: action, arg: arg })
}

// The rows, their submenus' too, acting on ids.
function about(ids, rows) {
  return rows.map(function(each) {
    return Object.assign({}, each, { ids: ids, children: about(ids, each.children) })
  })
}

// Picking the tag already set clears it.
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

// An investigation's actions by status; selection is the conversation's selected text.
function itemRows(item, tags, selection) {
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
  if (selection)
    rows.push(row({ key: "copySelection", text: "Copy selection", glyph: Format.icons.copy, action: "copy", arg: selection }))
  if (tags.length)
    rows.push(tagMenu(tags, item.tag))
  return rows
}

// A draft has Discard instead.
function deletable(item) {
  return item.status !== "running" && item.status !== "draft"
}

// A focused row: its investigation, or the picked set when there is one.
function rowRows(state, item) {
  if (state.picked.length)
    return pickedRows(state, true)
  var rows = [row({ key: "open", text: "Open", glyph: Format.icons[item.status], keys: ["Enter"], action: "open" })].concat(itemRows(item, state.tags, ""), [
    row({ key: "pick", text: "Pick", glyph: Format.icons.check, keys: ["Space"], action: "pick" }),
    row({ key: "combine", text: "Combine", glyph: Format.icons.plus, enabled: false, action: "combine" })
  ])
  if (deletable(item))
    rows.push(row({ key: "delete", text: "Delete", glyph: Format.icons.trash, keys: ["Backspace"], action: "delete" }))
  return about([item.id], rows)
}

// A right-clicked row: the picked set when it is picked, else its own
// investigation. Backspace on the row would delete the picked set, so its
// Delete shows no key while others are picked.
function contextRows(state, item) {
  if (state.picked.some(function(each) { return each.id === item.id }))
    return pickedRows(state, true)
  return rowRows(Object.assign({}, state, { picked: [] }), item).map(function(each) {
    return each.key === "delete" && state.picked.length ? Object.assign({}, each, { keys: [] }) : each
  })
}

// A tag shows on when every picked investigation has it; picking that one clears it from all.
function pickedRows(state, keyed) {
  var count = state.picked.length
  var rows = [row({ key: "combine", text: "Combine", glyph: Format.icons.plus, detail: count + (count === 1 ? " investigation" : " investigations"), enabled: count >= 2, action: "combine" })]
  if (state.tags.length) {
    var shared = state.tags.filter(function(tag) {
      return state.picked.every(function(item) { return item.tag === tag.name })
    })
    rows.push(tagMenu(state.tags, shared.length ? shared[0].name : ""))
  }
  rows.push(row({ key: "unpick", text: "Unpick", glyph: Format.icons.close, keys: keyed ? ["Esc"] : [], action: "unpick" }))
  var gone = state.picked.filter(function(item) { return item.status !== "running" }).length
  if (gone)
    rows.push(row({ key: "delete", text: "Delete " + gone, glyph: Format.icons.trash, keys: keyed ? ["Backspace"] : [], action: "delete" }))
  return about(state.picked.map(function(item) { return item.id }), rows)
}

// The filters: Tag › with each tag's count, Project ›.
function filterRows(state) {
  var rows = []
  if (state.tags.length)
    rows.push(submenu({ key: "filter.tag", text: "Tag", glyph: Format.icons.tag, detail: state.tagFilter }, [""].concat(state.tags.map(function(tag) { return tag.name })).map(function(name) {
      return Object.assign(radio("filter.tag." + name, name || "All", name === state.tagFilter, "filterTag", name), { detail: String(state.tagCounts[name] || 0) })
    })))
  if (state.projects.length)
    rows.push(submenu({ key: "filter.project", text: "Project", glyph: Format.icons.filter, detail: state.projectFilter.join(", ") }, [radio("filter.project.", "All projects", !state.projectFilter.length, "filterProject", "")].concat(state.projects.map(function(project) {
      return check("filter.project." + project, project, state.projectFilter.indexOf(project) >= 0, "filterProject", project)
    }))))
  return rows
}

// The list and its search field.
function listRows(state) {
  var rows = [row({ key: "search", text: "Search list", glyph: Format.icons.filter, action: "search" })]
  var filters = filterRows(state)
  if (filters.length)
    rows.push(submenu({ key: "filter", text: "Filter", glyph: Format.icons.filter, detail: [state.tagFilter].concat(state.projectFilter).filter(Boolean).join(", ") }, filters))
  if (state.listed.length > 1)
    rows.push(row({ key: "pickAll", text: "Pick all listed", glyph: Format.icons.checkOn, action: "pickAll" }))
  if (state.picked.length)
    rows.push(row({ key: "unpick", text: "Unpick", glyph: Format.icons.close, keys: ["Esc"], action: "unpick" }))
  if (state.listed.length)
    rows.push(submenu({ key: "goto", text: "Go to", glyph: Format.icons.arrow }, state.listed.map(function(item) {
      return row({ key: "goto." + item.id, text: Format.name(item), glyph: Format.icons[item.status], detail: item.projects.join(", "), action: "select", arg: item.id })
    })))
  return rows
}

// The shown draft's form. draft: id, tag and projects as the form holds them,
// and choices, every project it can pick. Projects › adds what is typed in it.
function draftRows(state, draft) {
  var rows = [
    row({ key: "run", text: "Run", glyph: Format.icons.play, keys: ["Ctrl", "Enter"], action: "run" }),
    row({ key: "discard", text: "Discard", glyph: Format.icons.trash, action: "discard" }),
    submenu({ key: "projects", text: "Projects", glyph: Format.icons.filter, detail: draft.projects.join(", ") }, draft.choices.map(function(project) {
      return check("projects." + project, project, draft.projects.indexOf(project) >= 0, "project", project)
    }).concat([row({ key: "projects.add", text: "Add a project…", glyph: Format.icons.plus, adds: true, action: "project" })]))
  ]
  if (state.tags.length)
    rows.push(tagMenu(state.tags, draft.tag))
  rows.push(row({ key: "trace", text: "Trace id", glyph: Format.icons.draft, action: "focusTrace" }))
  rows.push(row({ key: "notes", text: "Notes", glyph: Format.icons.draft, action: "focusNotes" }))
  return about([draft.id], rows)
}

// The shown investigation's conversation.
function conversationRows(state, item, selection) {
  var rows = itemRows(item, state.tags, selection)
  if (deletable(item))
    rows.push(row({ key: "delete", text: "Delete", glyph: Format.icons.trash, action: "delete" }))
  return about([item.id], rows)
}

// The rows of the submenu at key, for a chip's menu.
function submenuRows(rows, key) {
  var found = rows.filter(function(each) { return each.key === key })[0]
  return found ? found.children : []
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
  return rows
}
