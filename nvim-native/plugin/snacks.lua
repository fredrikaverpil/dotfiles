-- QoL via snacks.nvim: notifier, picker, dashboard, lazygit, terminal.
-- Replaces mini.pick (see removed plugin/pick.lua).

vim.pack.add({
  { src = "https://github.com/folke/snacks.nvim" },
})

require("snacks").setup({
  styles = {
    notification = {
      border = "rounded",
      wo = { winblend = 0, wrap = false },
    },
    notification_history = {
      relative = "editor",
      width = 0.9,
      height = 0.9,
    },
  },

  dashboard = {
    enabled = true,
    preset = {
      keys = {
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = " ", key = "s", desc = "Restore Session", action = ":lua require('persistence').load()" },
        { icon = " ", key = "u", desc = "Update Plugins", action = ":lua vim.pack.update()" },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      function()
        local found = vim.fs.find(".nvim.lua", { upward = true, type = "file" })
        if #found > 0 then
          local lines = {}
          for _, path in ipairs(found) do
            table.insert(lines, "  " .. vim.fn.fnamemodify(path, ":~"))
          end
          return {
            text = table.concat(lines, "\n"),
            align = "center",
            hl = "Comment",
            padding = 1,
          }
        end
        return { text = "" }
      end,
      function()
        if not _G._nvim_startup_ms then
          _G._nvim_startup_ms = _G._nvim_start_time
              and string.format("%.2f", (vim.uv.hrtime() - _G._nvim_start_time) / 1e6)
            or "?"
        end
        local ms = _G._nvim_startup_ms
        local plugin_count = #vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/*/*/*", false, true)
        return {
          align = "center",
          text = {
            { "⚡ Neovim loaded ", hl = "footer" },
            { tostring(plugin_count), hl = "special" },
            { " plugins in ", hl = "footer" },
            { ms .. "ms", hl = "special" },
          },
        }
      end,
    },
  },

  notifier = { enabled = true, timeout = 2000 },

  picker = {
    enabled = true,
    sources = {
      files = {
        hidden = true,
        ignored = false,
      },
    },
  },

  explorer = { enabled = true },

  lazygit = {
    enabled = true,
    configure = true,
    config = {
      os = { editPreset = "nvim-remote" },
      gui = { nerdFontsVersion = "3" },
      git = { overrideGpg = true },
    },
  },

  terminal = { enabled = true },

  quickfile = { enabled = true },

  zen = {
    enabled = true,
    toggles = {
      dim = false,
      git_signs = false,
      diagnostics = true,
    },
    win = { backdrop = { transparent = false } },
  },

  image = { enabled = true },
})

local function default_branch()
  return require("git").get_default_branch()
end

local exclude = {
  "*.pb.go",
  "**/.venv",
  ".mypy_cache/*",
  ".repro/*",
  "**/node_modules",
  ".sage/tools",
  ".pocket/tools",
}

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

local nmap = function(lhs, rhs, desc)
  map("n", lhs, rhs, desc)
end

-- Misc
nmap("<leader><leader>", function()
  Snacks.picker.smart({
    layout = { hidden = { "preview" } },
    multi = { "buffers", "files" },
    hidden = true,
    ignored = true,
    exclude = exclude,
    formatters = { file = { truncate = 100 } },
  })
end, "Files")
nmap("<leader>/", function()
  Snacks.picker.grep({
    layout = { hidden = { "preview" } },
    hidden = true,
    ignored = true,
    exclude = exclude,
  })
end, "Grep")
nmap("<leader>:", function()
  Snacks.picker.command_history()
end, "Command History")
nmap("<leader>D", function()
  Snacks.dashboard.open()
end, "Dashboard")

-- Explorer
nmap("<leader>e", function()
  Snacks.explorer.open({ hidden = true, ignored = true, exclude = { ".DS_Store" } })
end, "Explorer")
nmap("<leader>E", function()
  Snacks.explorer.reveal({ hidden = true, ignored = true })
end, "Explorer (reveal buffer)")

-- LSP (via picker)
nmap("gd", function()
  Snacks.picker.lsp_definitions()
end, "Goto Definition")
nmap("gs", function()
  vim.cmd("split")
  vim.lsp.buf.definition()
end, "Goto Definition (split)")
nmap("gv", function()
  vim.cmd("vsplit")
  vim.lsp.buf.definition()
end, "Goto Definition (vertical split)")
nmap("gD", function()
  Snacks.picker.lsp_declarations()
end, "Goto Declaration")
nmap("gr", function()
  Snacks.picker.lsp_references()
end, "References")
nmap("gI", function()
  Snacks.picker.lsp_implementations()
end, "Goto Implementation")
nmap("gt", function()
  Snacks.picker.lsp_type_definitions()
end, "Goto Type Definition")
nmap("<leader>ss", function()
  if vim.bo.filetype == "go" then
    local current_file = vim.fn.expand("%:t")
    local is_test_file = current_file:match("_test%.go$") ~= nil
    if is_test_file then
      require("pickers").go_package_symbols({ file_types = { "TestGoFiles", "XTestGoFiles" } })
    else
      require("pickers").go_package_symbols({ file_types = { "GoFiles", "CgoFiles" } })
    end
  else
    Snacks.picker.lsp_symbols()
  end
end, "LSP Symbols")
nmap("<leader>sS", function()
  Snacks.picker.lsp_workspace_symbols()
end, "LSP Symbols (workspace)")

-- Search
nmap('<leader>s"', function()
  Snacks.picker.registers()
end, "Registers")
nmap("<leader>sh", function()
  Snacks.picker.help()
end, "Help pages")
nmap("<leader>sa", function()
  Snacks.picker.autocmds()
end, "Autocommands")
nmap("<leader>sb", function()
  Snacks.picker.buffers()
end, "Buffers")
nmap("<leader>sc", function()
  Snacks.picker.commands()
end, "Commands")
nmap("<leader>sH", function()
  Snacks.picker.highlights()
end, "Highlight groups")
nmap("<leader>sk", function()
  Snacks.picker.keymaps()
end, "Keymaps")
nmap("<leader>sM", function()
  Snacks.picker.man()
end, "Man pages")
nmap("<leader>sm", function()
  Snacks.picker.marks()
end, "Marks")
nmap("<leader>sn", function()
  Snacks.picker.notifications()
end, "Notifications")
nmap("<leader>sj", function()
  Snacks.picker.jumps()
end, "Jumplist")
nmap("<leader>sp", function()
  Snacks.picker.projects({ dev = { "~/code/public", "~/code/work/private", "~/code/work/public" } })
end, "Projects")
nmap("<leader>sq", function()
  Snacks.picker.qflist()
end, "Quickfix List")
nmap("<leader>sF", function()
  Snacks.picker.recent()
end, "Recent files")
nmap("<leader>sd", function()
  Snacks.picker.diagnostics_buffer()
end, "Document diagnostics")
nmap("<leader>sD", function()
  Snacks.picker.diagnostics()
end, "Workspace diagnostics")
nmap("<leader>st", function()
  Snacks.picker.todo_comments()
end, "Todo")
nmap("<leader>sT", function()
  Snacks.picker.todo_comments({ keywords = { "TODO", "FIX" } })
end, "Todo/Fix/Fixme")
nmap("<leader>sz", function()
  Snacks.picker.zoxide()
end, "Zoxide")
nmap("<leader>sP", function()
  require("pickers").pull_requests()
end, "Pull Requests")
nmap("<leader>sl", function()
  require("pickers").neovim_logs()
end, "Neovim logs")

-- Git
nmap("<leader>gg", function()
  Snacks.lazygit.open()
end, "LazyGit")
nmap("<leader>sgc", function()
  Snacks.picker.git_log()
end, "Git commit log")
nmap("<leader>sgd", function()
  Snacks.picker.git_diff({ base = default_branch() })
end, "Git Diff (default branch)")
nmap("<leader>gdp", function()
  Snacks.picker.git_diff({ base = default_branch() })
end, "Git Diff Picker (default branch)")
nmap("<leader>sgD", function()
  Snacks.picker.git_diff()
end, "Git Diff (HEAD)")
nmap("<leader>gdP", function()
  Snacks.picker.git_diff()
end, "Git Diff Picker (HEAD)")
nmap("<leader>sgf", function()
  Snacks.picker.git_log_file()
end, "Git commit log (file)")
nmap("<leader>sgl", function()
  Snacks.picker.git_log_line()
end, "Git commit log (line)")
nmap("<leader>sgs", function()
  Snacks.picker.git_status()
end, "Git status")
nmap("<leader>sgS", function()
  Snacks.picker.git_stash()
end, "Git stash")
nmap("<leader>sgb", function()
  Snacks.picker.git_branches()
end, "Git branches")

-- UI
nmap("<leader>uz", function()
  Snacks.zen.zen()
end, "Toggle Zen mode")
nmap("<leader>un", function()
  Snacks.notifier.show_history()
end, "Notification history")

-- Terminal
-- Both <C-/> and <C-_> are mapped due to how terminal emulators interpret control characters.
local function floating_term()
  Snacks.terminal.toggle({ "zsh" }, { cwd = vim.fn.getcwd() })
end
map({ "n", "i", "t", "v" }, "<C-/>", floating_term, "Toggle floating terminal")
map({ "n", "i", "t", "v" }, "<C-_>", floating_term, "Toggle floating terminal")
map("t", "<Esc><Esc>", "<C-\\><C-n>", "Exit terminal mode")
nmap("<leader>ft", function()
  Snacks.terminal()
end, "Terminal")
