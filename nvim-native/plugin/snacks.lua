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
        { icon = " ", key = "u", desc = "Check for Updates", action = ":Pack check" },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      function()
        local entries = require("exrc").list()
        if #entries == 0 then
          return { text = "" }
        end
        local suffix = {
          trusted = "",
          modified = " (modified — re-run :trust)",
          denied = " (denied)",
          untrusted = " (untrusted — run :trust)",
          unreadable = " (unreadable)",
        }
        local lines = {}
        for _, e in ipairs(entries) do
          table.insert(lines, "  " .. e.path .. suffix[e.status])
        end
        return {
          text = table.concat(lines, "\n"),
          align = "center",
          hl = "Comment",
          padding = 1,
        }
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

-- Misc
vim.keymap.set("n", "<leader><leader>", function()
  Snacks.picker.smart({
    layout = { hidden = { "preview" } },
    multi = { "buffers", "files" },
    hidden = true,
    ignored = true,
    exclude = exclude,
    formatters = { file = { truncate = 100 } },
  })
end, { desc = "Files" })
vim.keymap.set("n", "<leader>/", function()
  Snacks.picker.grep({
    layout = { hidden = { "preview" } },
    hidden = true,
    ignored = true,
    exclude = exclude,
  })
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>:", function()
  Snacks.picker.command_history()
end, { desc = "Command History" })
vim.keymap.set("n", "<leader>D", function()
  Snacks.dashboard.open()
end, { desc = "Dashboard" })

-- Explorer
vim.keymap.set("n", "<leader>e", function()
  Snacks.explorer.open({ hidden = true, ignored = true, exclude = { ".DS_Store" } })
end, { desc = "Explorer" })
vim.keymap.set("n", "<leader>E", function()
  Snacks.explorer.reveal({ hidden = true, ignored = true })
end, { desc = "Explorer (reveal buffer)" })

-- LSP (via picker)
vim.keymap.set("n", "gd", function()
  Snacks.picker.lsp_definitions()
end, { desc = "Goto Definition" })
vim.keymap.set("n", "gs", function()
  vim.cmd("split")
  vim.lsp.buf.definition()
end, { desc = "Goto Definition (split)" })
vim.keymap.set("n", "gv", function()
  vim.cmd("vsplit")
  vim.lsp.buf.definition()
end, { desc = "Goto Definition (vertical split)" })
vim.keymap.set("n", "gD", function()
  Snacks.picker.lsp_declarations()
end, { desc = "Goto Declaration" })
vim.keymap.set("n", "gr", function()
  Snacks.picker.lsp_references()
end, { desc = "References" })
vim.keymap.set("n", "gI", function()
  Snacks.picker.lsp_implementations()
end, { desc = "Goto Implementation" })
vim.keymap.set("n", "gt", function()
  Snacks.picker.lsp_type_definitions()
end, { desc = "Goto Type Definition" })
vim.keymap.set("n", "<leader>ss", function()
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
end, { desc = "LSP Symbols" })
vim.keymap.set("n", "<leader>sS", function()
  Snacks.picker.lsp_workspace_symbols()
end, { desc = "LSP Symbols (workspace)" })

-- Search
vim.keymap.set("n", '<leader>s"', function()
  Snacks.picker.registers()
end, { desc = "Registers" })
vim.keymap.set("n", "<leader>sh", function()
  Snacks.picker.help()
end, { desc = "Help pages" })
vim.keymap.set("n", "<leader>sa", function()
  Snacks.picker.autocmds()
end, { desc = "Autocommands" })
vim.keymap.set("n", "<leader>sb", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>sc", function()
  Snacks.picker.commands()
end, { desc = "Commands" })
vim.keymap.set("n", "<leader>sH", function()
  Snacks.picker.highlights()
end, { desc = "Highlight groups" })
vim.keymap.set("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>sM", function()
  Snacks.picker.man()
end, { desc = "Man pages" })
vim.keymap.set("n", "<leader>sm", function()
  Snacks.picker.marks()
end, { desc = "Marks" })
vim.keymap.set("n", "<leader>sn", function()
  Snacks.picker.notifications()
end, { desc = "Notifications" })
vim.keymap.set("n", "<leader>sj", function()
  Snacks.picker.jumps()
end, { desc = "Jumplist" })
vim.keymap.set("n", "<leader>sp", function()
  Snacks.picker.projects({ dev = { "~/code/public", "~/code/work/private", "~/code/work/public" } })
end, { desc = "Projects" })
vim.keymap.set("n", "<leader>sq", function()
  Snacks.picker.qflist()
end, { desc = "Quickfix List" })
vim.keymap.set("n", "<leader>sF", function()
  Snacks.picker.recent()
end, { desc = "Recent files" })
vim.keymap.set("n", "<leader>sd", function()
  Snacks.picker.diagnostics_buffer()
end, { desc = "Document diagnostics" })
vim.keymap.set("n", "<leader>sD", function()
  Snacks.picker.diagnostics()
end, { desc = "Workspace diagnostics" })
vim.keymap.set("n", "<leader>st", function()
  Snacks.picker.todo_comments()
end, { desc = "Todo" })
vim.keymap.set("n", "<leader>sT", function()
  Snacks.picker.todo_comments({ keywords = { "TODO", "FIX" } })
end, { desc = "Todo/Fix/Fixme" })
vim.keymap.set("n", "<leader>sz", function()
  Snacks.picker.zoxide()
end, { desc = "Zoxide" })
vim.keymap.set("n", "<leader>sP", function()
  require("pickers").pull_requests()
end, { desc = "Pull Requests" })
vim.keymap.set("n", "<leader>sl", function()
  require("pickers").neovim_logs()
end, { desc = "Neovim logs" })

-- Git
vim.keymap.set("n", "<leader>gg", function()
  Snacks.lazygit.open()
end, { desc = "LazyGit" })
vim.keymap.set("n", "<leader>sgc", function()
  Snacks.picker.git_log()
end, { desc = "Git commit log" })
vim.keymap.set("n", "<leader>sgd", function()
  Snacks.picker.git_diff({ base = default_branch() })
end, { desc = "Git Diff (default branch)" })
vim.keymap.set("n", "<leader>gdp", function()
  Snacks.picker.git_diff({ base = default_branch() })
end, { desc = "Git Diff Picker (default branch)" })
vim.keymap.set("n", "<leader>sgD", function()
  Snacks.picker.git_diff()
end, { desc = "Git Diff (HEAD)" })
vim.keymap.set("n", "<leader>gdP", function()
  Snacks.picker.git_diff()
end, { desc = "Git Diff Picker (HEAD)" })
vim.keymap.set("n", "<leader>sgf", function()
  Snacks.picker.git_log_file()
end, { desc = "Git commit log (file)" })
vim.keymap.set("n", "<leader>sgl", function()
  Snacks.picker.git_log_line()
end, { desc = "Git commit log (line)" })
vim.keymap.set("n", "<leader>sgs", function()
  Snacks.picker.git_status()
end, { desc = "Git status" })
vim.keymap.set("n", "<leader>sgS", function()
  Snacks.picker.git_stash()
end, { desc = "Git stash" })
vim.keymap.set("n", "<leader>sgb", function()
  Snacks.picker.git_branches()
end, { desc = "Git branches" })

-- UI
vim.keymap.set("n", "<leader>uz", function()
  Snacks.zen.zen()
end, { desc = "Toggle Zen mode" })
vim.keymap.set("n", "<leader>un", function()
  Snacks.notifier.show_history()
end, { desc = "Notification history" })

-- Terminal
-- Both <C-/> and <C-_> are mapped due to how terminal emulators interpret control characters.
local function floating_term()
  Snacks.terminal.toggle({ "zsh" }, { cwd = vim.fn.getcwd() })
end
vim.keymap.set({ "n", "i", "t", "v" }, "<C-/>", floating_term, { desc = "Toggle floating terminal" })
vim.keymap.set({ "n", "i", "t", "v" }, "<C-_>", floating_term, { desc = "Toggle floating terminal" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", "<leader>ft", function()
  Snacks.terminal()
end, { desc = "Terminal" })
