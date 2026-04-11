--
-- Minimalistic vim.pack UI
--
-- Provides :Pack command that opens a floating window dashboard
-- for managing plugins (update, clean, log, inspect).
--

local api = vim.api
local ns = api.nvim_create_namespace("pack_ui")

-- Highlight groups
local function setup_highlights()
  local links = {
    PackUiHeader = "Title",
    PackUiButton = "Function",
    PackUiPluginLoaded = "String",
    PackUiPluginNotLoaded = "Comment",
    PackUiPluginMissing = "ErrorMsg",
    PackUiUpdateAvailable = "DiagnosticInfo",
    PackUiBreaking = "DiagnosticWarn",
    PackUiVersion = "Number",
    PackUiSectionHeader = "Label",
    PackUiSeparator = "FloatBorder",
    PackUiDetail = "Comment",
    PackUiHelp = "SpecialComment",
  }
  for group, target in pairs(links) do
    api.nvim_set_hl(0, group, { link = target, default = true })
  end
end

-- State
local state = {
  bufnr = nil,
  winid = nil,
  win_autocmd_id = nil, -- WinClosed autocmd ID
  line_to_plugin = {}, -- line number (1-based) => plugin name
  plugin_lines = {}, -- plugin name => line number (1-based)
  expanded = {}, -- plugin name => bool
  show_help = false,
  updates = {}, -- plugin name => list of new commit lines
  breaking_version = {}, -- plugin name => bool (major semver bump detected)
  checking = false, -- true while fetching remote updates
}

-- Cache of path => installed git tag (false = no tag found)
local tag_cache = {}

-- For versioned plugins, return the actual installed tag from git.
-- Results are cached for the session so git is only called once per plugin.
local function get_installed_tag(path)
  if not path then
    return nil
  end
  if tag_cache[path] ~= nil then
    return tag_cache[path] or nil
  end
  local result =
    vim.fn.system("git -C " .. vim.fn.shellescape(path) .. " describe --tags --exact-match HEAD 2>/dev/null")
  if vim.v.shell_error == 0 then
    local tag = vim.trim(result)
    tag_cache[path] = tag
    return tag
  end
  tag_cache[path] = false
  return nil
end

-- Get version string from plugin spec
local function get_version_str(p)
  local v = p.spec.version
  if v == nil then
    return ""
  end
  if type(v) == "string" then
    return v
  end
  return tostring(v)
end

-- Forward declaration (check_updates calls render before it is defined)
local render

-- Resolve the remote default branch ref for a git repo.
-- Calls callback(ref_string) or callback(nil) on failure.
local function resolve_remote_ref(path, callback)
  vim.system({ "git", "-C", path, "symbolic-ref", "refs/remotes/origin/HEAD" }, { text = true }, function(result)
    if result.code == 0 then
      callback(vim.trim(result.stdout))
      return
    end
    vim.system({ "git", "-C", path, "rev-parse", "--verify", "origin/main" }, { text = true }, function(r)
      if r.code == 0 then
        callback("origin/main")
      else
        vim.system({ "git", "-C", path, "rev-parse", "--verify", "origin/master" }, { text = true }, function(r2)
          callback(r2.code == 0 and "origin/master" or nil)
        end)
      end
    end)
  end)
end

-- Fetch all plugins and check for new commits on the remote
local function check_updates()
  if state.checking then
    return
  end

  local plugins = vim.pack.get(nil, { info = false })
  if #plugins == 0 then
    return
  end

  state.checking = true
  state.updates = {}
  state.breaking_version = {}
  render()

  local remaining = #plugins

  local function finish_one()
    vim.schedule(function()
      remaining = remaining - 1
      if remaining == 0 then
        state.checking = false
        render()
      end
    end)
  end

  for _, p in ipairs(plugins) do
    local path = p.path
    local name = p.spec.name
    local current_tag = p.spec.version and get_installed_tag(path) or nil

    vim.system({ "git", "-C", path, "fetch", "--quiet", "--tags" }, {}, function(fetch_res)
      if fetch_res.code ~= 0 then
        finish_one()
        return
      end
      resolve_remote_ref(path, function(ref)
        if not ref then
          finish_one()
          return
        end
        vim.system({ "git", "-C", path, "log", "--oneline", "HEAD.." .. ref }, { text = true }, function(log_res)
          local commits = {}
          if log_res.code == 0 and log_res.stdout ~= "" then
            for line in log_res.stdout:gmatch("[^\n]+") do
              table.insert(commits, line)
            end
          end
          state.updates[name] = commits

          -- Check for major semver bump
          if not current_tag then
            finish_one()
            return
          end
          vim.system(
            { "git", "-C", path, "tag", "--list", "--sort=-version:refname" },
            { text = true },
            function(tag_res)
              if tag_res.code == 0 then
                local latest_tag = tag_res.stdout:match("[^\n]+")
                if latest_tag then
                  local cur_major = tonumber(current_tag:match("^v?(%d+)"))
                  local new_major = tonumber(latest_tag:match("^v?(%d+)"))
                  if cur_major and new_major and new_major > cur_major then
                    state.breaking_version[name] = true
                  end
                end
              end
              finish_one()
            end
          )
        end)
      end)
    end)
  end
end

-- Build lines and highlights for the buffer
local function build_content()
  local plugins = vim.pack.get(nil, { info = false })

  local loaded = {}
  local not_loaded = {}
  for _, p in ipairs(plugins) do
    if p.active then
      table.insert(loaded, p)
    else
      table.insert(not_loaded, p)
    end
  end

  table.sort(loaded, function(a, b)
    return a.spec.name < b.spec.name
  end)
  table.sort(not_loaded, function(a, b)
    return a.spec.name < b.spec.name
  end)

  local lines = {}
  local hls = {} -- { line, col_start, col_end, hl_group }
  local line_to_plugin = {}
  local plugin_lines = {}

  local function add(text, hl)
    local lnum = #lines
    lines[#lines + 1] = text
    if hl then
      table.insert(hls, { lnum, 0, #text, hl })
    end
  end

  local function add_hl(lnum, col_start, col_end, hl)
    table.insert(hls, { lnum, col_start, col_end, hl })
  end

  -- Header
  local status = state.checking and "  (checking...)" or ""
  local header = string.format(" vim.pack -- %d plugins | %d loaded%s", #plugins, #loaded, status)
  add(header, "PackUiHeader")

  -- Separator (fill the window width minus the leading space)
  local win_width = state.winid and vim.api.nvim_win_get_width(state.winid) or 80
  local sep = " " .. string.rep("─", win_width - 1)
  add(sep, "PackUiSeparator")

  -- Action bar
  local bar = " [U]pdate All  [u] Update  [C]heck  [X] Clean  [D]elete  [L] Log  [?] Help"
  add(bar)
  -- Highlight the bracket keys (gmatch () captures are 1-based;
  -- the end capture points one past the match, which is exactly
  -- the exclusive end_col that extmarks expect)
  local lnum = #lines - 1
  for s, e in bar:gmatch("()%[.-%]()") do
    add_hl(lnum, s - 1, e - 1, "PackUiButton")
  end

  -- Help section (toggled)
  if state.show_help then
    add("")
    add(" Keymaps:", "PackUiHelp")
    add("   U       Update all plugins", "PackUiHelp")
    add("   u       Update plugin under cursor", "PackUiHelp")
    add("   C       Check remote for new commits", "PackUiHelp")
    add("   X       Clean non-active plugins", "PackUiHelp")
    add("   D       Delete plugin under cursor (non-active only)", "PackUiHelp")
    add("   L       Open update log file", "PackUiHelp")
    add("   <CR>    Toggle plugin details", "PackUiHelp")
    add("   ]]      Jump to next plugin", "PackUiHelp")
    add("   [[      Jump to previous plugin", "PackUiHelp")
    add("   q/Esc   Close window", "PackUiHelp")
  end

  -- Compute max name width for alignment
  local max_name = 0
  for _, p in ipairs(plugins) do
    max_name = math.max(max_name, #p.spec.name)
  end

  -- Render a plugin line
  -- Format: '   %s %s%s%s' => 3 spaces, icon, 1 space, name, pad, version
  -- Byte offsets: icon starts at 3, name starts at 3 + #icon_bytes + 1
  local function render_plugin(p, icon, hl_group)
    local name = p.spec.name
    local pad = string.rep(" ", max_name - #name + 2)
    local version = get_version_str(p)
    local tag = p.spec.version and get_installed_tag(p.path) or nil
    local rev_short = p.rev and p.rev:sub(1, 7) or ""

    local ver_display = tag or (rev_short ~= "" and rev_short or version)
    local update_count = state.updates[name] and #state.updates[name] or 0
    local update_str = update_count > 0 and string.format("  ↑%d", update_count) or ""
    local line = string.format("   %s %s%s%s%s", icon, name, pad, ver_display, update_str)
    local lnum_cur = #lines
    add(line)

    -- Byte offsets for highlights
    local icon_bytes = #icon
    local icon_start = 3
    local name_start = icon_start + icon_bytes + 1

    add_hl(lnum_cur, icon_start, icon_start + icon_bytes, hl_group)
    add_hl(lnum_cur, name_start, name_start + #name, hl_group)
    if #ver_display > 0 then
      local ver_start = name_start + #name + #pad
      local ver_hl = state.breaking_version[name] and "PackUiBreaking" or "PackUiVersion"
      add_hl(lnum_cur, ver_start, ver_start + #ver_display, ver_hl)
    end
    if update_count > 0 then
      local update_start = name_start + #name + #pad + #ver_display
      add_hl(lnum_cur, update_start, update_start + #update_str, "PackUiUpdateAvailable")
    end

    -- Track plugin position (1-based line number for cursor operations)
    line_to_plugin[lnum_cur + 1] = name
    plugin_lines[name] = lnum_cur + 1

    -- Expanded details
    if state.expanded[name] then
      local details = {
        string.format("     Path:    %s", p.path),
        string.format("     Source:  %s", p.spec.src),
      }
      if p.rev then
        table.insert(details, string.format("     Rev:     %s", p.rev))
      end
      for _, d in ipairs(details) do
        add(d, "PackUiDetail")
      end
      local commits = state.updates[name]
      if commits and #commits > 0 then
        local max_commits = 10
        for i, c in ipairs(commits) do
          if i > max_commits then
            add(string.format("     ... and %d more", #commits - max_commits), "PackUiDetail")
            break
          end
          -- Detect breaking changes: conventional commits "type!:" or "type(scope)!:"
          local is_breaking = c:match("%x+ %w+!:") or c:match("%x+ %w+%b()!:")
          add("     " .. c, is_breaking and "PackUiBreaking" or nil)
        end
      end
    end
  end

  -- Loaded section
  add("")
  add(string.format(" Loaded (%d)", #loaded), "PackUiSectionHeader")
  for _, p in ipairs(loaded) do
    render_plugin(p, "●", "PackUiPluginLoaded")
  end

  -- Not Loaded section
  if #not_loaded > 0 then
    add("")
    add(string.format(" Not Loaded (%d)", #not_loaded), "PackUiSectionHeader")
    for _, p in ipairs(not_loaded) do
      render_plugin(p, "○", "PackUiPluginNotLoaded")
    end
  end

  state.line_to_plugin = line_to_plugin
  state.plugin_lines = plugin_lines

  return lines, hls
end

-- Render content into the buffer
render = function()
  if not state.bufnr or not api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  local lines, hls = build_content()

  vim.bo[state.bufnr].modifiable = true
  api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.bo[state.bufnr].modifiable = false
  vim.bo[state.bufnr].modified = false

  -- Apply highlights
  api.nvim_buf_clear_namespace(state.bufnr, ns, 0, -1)
  for _, hl in ipairs(hls) do
    api.nvim_buf_set_extmark(state.bufnr, ns, hl[1], hl[2], {
      end_col = hl[3],
      hl_group = hl[4],
    })
  end
end

-- Get plugin name at cursor
local function plugin_at_cursor()
  if not state.winid or not api.nvim_win_is_valid(state.winid) then
    return nil
  end
  local row = api.nvim_win_get_cursor(state.winid)[1]
  return state.line_to_plugin[row]
end

-- Close the floating window
local function close()
  -- Remove autocmd first to prevent it from corrupting state on re-open
  if state.win_autocmd_id then
    pcall(api.nvim_del_autocmd, state.win_autocmd_id)
    state.win_autocmd_id = nil
  end
  if state.winid and api.nvim_win_is_valid(state.winid) then
    api.nvim_win_close(state.winid, true)
  end
  -- Buffer has bufhidden=wipe, so it is wiped when the window closes.
  -- No need to explicitly delete it.
  state.winid = nil
  state.bufnr = nil
  state.expanded = {}
  state.show_help = false
  state.updates = {}
  state.breaking_version = {}
  state.checking = false
end

-- Jump to next/prev plugin line
local function jump_plugin(direction)
  if not state.winid or not api.nvim_win_is_valid(state.winid) then
    return
  end
  local row = api.nvim_win_get_cursor(state.winid)[1]

  -- Collect sorted plugin line numbers
  local plines = {}
  for lnum, _ in pairs(state.line_to_plugin) do
    table.insert(plines, lnum)
  end
  table.sort(plines)

  if direction > 0 then
    for _, lnum in ipairs(plines) do
      if lnum > row then
        api.nvim_win_set_cursor(state.winid, { lnum, 0 })
        return
      end
    end
    -- Wrap around
    if #plines > 0 then
      api.nvim_win_set_cursor(state.winid, { plines[1], 0 })
    end
  else
    for i = #plines, 1, -1 do
      if plines[i] < row then
        api.nvim_win_set_cursor(state.winid, { plines[i], 0 })
        return
      end
    end
    -- Wrap around
    if #plines > 0 then
      api.nvim_win_set_cursor(state.winid, { plines[#plines], 0 })
    end
  end
end

-- Forward declaration so keymap closures can reference open() before it is
-- defined (Lua closures capture locals by reference, but the local must be
-- declared in an enclosing scope at the point where the closure is created).
local open

-- Setup buffer keymaps (buffer-local, survive re-focus since buffer persists)
local function setup_keymaps()
  local buf = state.bufnr
  local opts = { buffer = buf, silent = true, nowait = true }

  -- Close
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)

  -- Update all
  vim.keymap.set("n", "U", function()
    close()
    vim.pack.update()
  end, opts)

  -- Update plugin under cursor
  vim.keymap.set("n", "u", function()
    local name = plugin_at_cursor()
    if name then
      close()
      vim.pack.update({ name })
    end
  end, opts)

  -- Clean non-active plugins
  vim.keymap.set("n", "X", function()
    local to_clean = vim
      .iter(vim.pack.get(nil, { info = false }))
      :filter(function(x)
        return not x.active
      end)
      :map(function(x)
        return x.spec.name
      end)
      :totable()

    if #to_clean == 0 then
      vim.notify("vim.pack: nothing to clean", vim.log.levels.INFO)
      return
    end

    local msg = string.format("Remove %d non-active plugin(s)?\n\n%s", #to_clean, table.concat(to_clean, "\n"))
    local choice = vim.fn.confirm(msg, "&Yes\n&No", 2, "Question")
    if choice == 1 then
      close()
      local ok, err = pcall(vim.pack.del, to_clean)
      if ok then
        vim.notify(string.format("vim.pack: removed %d plugin(s)", #to_clean), vim.log.levels.INFO)
      else
        vim.notify("vim.pack: " .. tostring(err), vim.log.levels.ERROR)
      end
    end
  end, opts)

  -- Delete plugin under cursor
  vim.keymap.set("n", "D", function()
    local name = plugin_at_cursor()
    if not name then
      return
    end

    -- Check if active
    local ok, pdata = pcall(vim.pack.get, { name }, { info = false })
    if not ok then
      vim.notify(string.format("vim.pack: %s is not installed", name), vim.log.levels.WARN)
      return
    end
    if #pdata > 0 and pdata[1].active then
      vim.notify(string.format("vim.pack: %s is active, remove from config first", name), vim.log.levels.WARN)
      return
    end

    local choice = vim.fn.confirm(string.format("Delete plugin %s?", name), "&Yes\n&No", 2, "Question")
    if choice == 1 then
      close()
      local del_ok, err = pcall(vim.pack.del, { name })
      if del_ok then
        vim.notify(string.format("vim.pack: removed %s", name), vim.log.levels.INFO)
      else
        vim.notify("vim.pack: " .. tostring(err), vim.log.levels.ERROR)
      end
    end
  end, opts)

  -- Open log
  vim.keymap.set("n", "L", function()
    close()
    local log_path = vim.fs.joinpath(vim.fn.stdpath("log"), "nvim-pack.log")
    if vim.uv.fs_stat(log_path) then
      vim.cmd.edit(log_path)
    else
      vim.notify("vim.pack: no log file yet", vim.log.levels.INFO)
    end
  end, opts)

  -- Toggle details
  vim.keymap.set("n", "<CR>", function()
    local name = plugin_at_cursor()
    if name then
      state.expanded[name] = not state.expanded[name]
      render()
      -- Restore cursor to the plugin line
      if state.plugin_lines[name] then
        api.nvim_win_set_cursor(state.winid, { state.plugin_lines[name], 0 })
      end
    end
  end, opts)

  -- Navigation
  vim.keymap.set("n", "]]", function()
    jump_plugin(1)
  end, opts)
  vim.keymap.set("n", "[[", function()
    jump_plugin(-1)
  end, opts)

  -- Check for updates
  vim.keymap.set("n", "C", check_updates, opts)

  -- Help toggle
  vim.keymap.set("n", "?", function()
    state.show_help = not state.show_help
    render()
  end, opts)
end

-- Open the Pack UI
open = function()
  -- If already open, focus it
  if state.winid and api.nvim_win_is_valid(state.winid) then
    api.nvim_set_current_win(state.winid)
    return
  end

  setup_highlights()

  -- Create buffer
  state.bufnr = api.nvim_create_buf(false, true)
  vim.bo[state.bufnr].buftype = "nofile"
  vim.bo[state.bufnr].bufhidden = "wipe"
  vim.bo[state.bufnr].swapfile = false
  vim.bo[state.bufnr].filetype = "pack-ui"

  -- Calculate window size
  local cols = vim.o.columns
  local lines = vim.o.lines
  local width = math.min(cols - 4, math.max(math.floor(cols * 0.8), 60))
  local height = math.min(lines - 4, math.max(math.floor(lines * 0.7), 20))
  local row = math.floor((lines - height) / 2)
  local col = math.floor((cols - width) / 2)

  -- Create floating window
  state.winid = api.nvim_open_win(state.bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " vim.pack ",
    title_pos = "center",
  })

  vim.wo[state.winid].cursorline = true
  vim.wo[state.winid].wrap = false

  -- Render content
  render()

  -- Setup keymaps
  setup_keymaps()

  -- Track WinClosed to clean up state if the window is closed externally
  -- (e.g., :quit, <C-w>c). Store the autocmd ID so close() can remove it
  -- to prevent races when re-opening immediately after an explicit close.
  local captured_winid = state.winid
  state.win_autocmd_id = api.nvim_create_autocmd("WinClosed", {
    buffer = state.bufnr,
    once = true,
    callback = function(ev)
      -- Only clean up if the closed window matches the one we opened
      if vim._tointeger(ev.match) ~= captured_winid then
        return
      end
      state.winid = nil
      state.bufnr = nil
      state.win_autocmd_id = nil
      state.expanded = {}
      state.show_help = false
      state.updates = {}
      state.breaking_version = {}
      state.checking = false
    end,
  })
end

-- Register :Pack command
vim.api.nvim_create_user_command("Pack", function()
  open()
end, { desc = "Open vim.pack plugin manager UI" })
