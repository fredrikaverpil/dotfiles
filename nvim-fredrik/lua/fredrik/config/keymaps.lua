local M = {}

-- windows
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window", silent = true, noremap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", silent = true, noremap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", silent = true, noremap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window", silent = true, noremap = true })
-- Resize windows using <ctrl> arrow keys
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height", silent = true })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height", silent = true })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width", silent = true })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width", silent = true })
-- Move between tmux windows (seems to work fine without these keymaps)
-- keys = {
--   { "n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", desc = "Navigate Left" },
--   { "n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", desc = "Navigate Down" },
--   { "n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", desc = "Navigate Up" },
--   { "n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Navigate Right" },
--   { "n", "<C-\\>", "<cmd>TmuxNavigatePrevious<CR>", desc = "Navigate Previous" },
-- },

-- Move Lines
local is_mac = vim.fn.has("macunix") == 1
local down_keys = is_mac and { "∆", "<M-j>", "<A-j>" } or { "<M-j>" }
local up_keys = is_mac and { "˚", "<M-k>", "<A-k>" } or { "<M-k>" }
-- Helper function to set multiple mappings for the same action
local function map_multiple(mode, keys, command, opts)
  for _, key in ipairs(keys) do
    vim.keymap.set(mode, key, command, opts)
  end
end
-- Normal mode
map_multiple("n", down_keys, ":m .+1<CR>==", { desc = "Move line down", silent = true })
map_multiple("n", up_keys, ":m .-2<CR>==", { desc = "Move line up", silent = true })
-- Insert mode
map_multiple("i", down_keys, "<Esc>:m .+1<CR>==gi", { desc = "Move line down", silent = true })
map_multiple("i", up_keys, "<Esc>:m .-2<CR>==gi", { desc = "Move line up", silent = true })
-- Visual mode
map_multiple("v", down_keys, ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
map_multiple("v", up_keys, ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- buffers
vim.keymap.set("n", "<leader>`", "<C-^>", { noremap = true, desc = "Alternate buffers" })
vim.keymap.set("n", "<leader>bN", "<cmd>enew<cr>", { desc = "New buffer" })
for _, key in ipairs({ "<S-l>", "<leader>bn", "]b" }) do
  vim.keymap.set("n", key, "<cmd>bnext<cr>", { desc = "Next buffer" })
end
for _, key in ipairs({ "<S-h>", "<leader>bp", "[b" }) do
  vim.keymap.set("n", key, "<cmd>bprevious<cr>", { desc = "Prev buffer" })
end
vim.keymap.set("n", "<leader>bq", "<cmd>bd %<cr>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>bo", function()
  local visible = {}
  for _, win in pairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(win)] = true
  end
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if not visible[buf] then
      vim.api.nvim_buf_delete(buf, {})
    end
  end
end, { desc = "Close all other buffers" })

-- tabs (can also use gt and gT)
-- vim.keymap.set("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab", silent = true })
-- vim.keymap.set("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab", silent = true })
vim.keymap.set("n", "<leader><tab>n", "<cmd>tabnew<cr>", { desc = "New Tab", silent = true })
vim.keymap.set("n", "<leader><tab>q", "<cmd>tabclose<cr>", { desc = "Close Tab", silent = true })
vim.keymap.set("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab", silent = true })
vim.keymap.set("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab", silent = true })
vim.keymap.set("n", "[<tab>", "<cmd>tabprevious<cr>", { desc = "Previous Tab", silent = true })
vim.keymap.set("n", "]<tab>", "<cmd>tabnext<cr>", { desc = "Next Tab", silent = true })

-- Clear search with <esc>
vim.keymap.set({ "n", "i" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- save file
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- better indenting
vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })

-- Lazy.nvim
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- lists
vim.keymap.set("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })
vim.keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
vim.keymap.set("n", "<leader>xc", function()
  vim.fn.setloclist(0, {})
end, { desc = "Clear location list" })
vim.keymap.set("n", "<leader>xC", function()
  vim.fn.setqflist({})
end, { desc = "Clear quickfix list" })
-- Vim error code for empty quickfix/location list
local EMPTY_LIST_ERROR = "E42"

vim.keymap.set("n", "[q", function()
  local ok, err = pcall(vim.cmd.cprev)
  if not ok and err:match(EMPTY_LIST_ERROR) then
    -- Quickfix list is empty, check if there are diagnostics to populate
    local diagnostics = vim.diagnostic.get()
    if #diagnostics > 0 then
      require("fredrik.utils.quickfix").toggle_qflist()
      vim.cmd.cfirst()
    else
      vim.notify("No items in quickfix list", vim.log.levels.INFO)
    end
  end
end, { desc = "Previous quickfix" })
vim.keymap.set("n", "]q", function()
  local ok, err = pcall(vim.cmd.cnext)
  if not ok and err:match(EMPTY_LIST_ERROR) then
    -- Quickfix list is empty, check if there are diagnostics to populate
    local diagnostics = vim.diagnostic.get()
    if #diagnostics > 0 then
      require("fredrik.utils.quickfix").toggle_qflist()
      vim.cmd.cfirst()
    else
      vim.notify("No items in quickfix list", vim.log.levels.INFO)
    end
  end
end, { desc = "Next quickfix" })
vim.keymap.set("n", "[l", function()
  local ok, err = pcall(vim.cmd.lprev)
  if not ok and err:match(EMPTY_LIST_ERROR) then
    -- Location list is empty, check if there are diagnostics to populate
    local diagnostics = vim.diagnostic.get(0)
    if #diagnostics > 0 then
      require("fredrik.utils.quickfix").toggle_loclist()
      vim.cmd.lfirst()
    else
      vim.notify("No items in location list", vim.log.levels.INFO)
    end
  end
end, { desc = "Previous location" })
vim.keymap.set("n", "]l", function()
  local ok, err = pcall(vim.cmd.lnext)
  if not ok and err:match(EMPTY_LIST_ERROR) then
    -- Location list is empty, check if there are diagnostics to populate
    local diagnostics = vim.diagnostic.get(0)
    if #diagnostics > 0 then
      require("fredrik.utils.quickfix").toggle_loclist()
      vim.cmd.lfirst()
    else
      vim.notify("No items in location list", vim.log.levels.INFO)
    end
  end
end, { desc = "Next location" })
vim.keymap.set("n", "<leader>xx", function()
  require("fredrik.utils.quickfix").toggle_loclist()
end, { desc = "Toggle buffer diagnostics (location list)", silent = true })
vim.keymap.set("n", "<leader>xX", function()
  require("fredrik.utils.quickfix").toggle_qflist()
end, { desc = "Toggle workspace diagnostics (quickfix list)", silent = true })

-- diagnostic
local function diagnostic_goto(count, severity)
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    vim.diagnostic.jump({ count = count, severity = severity })
  end
end
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "]d", diagnostic_goto(1), { desc = "Next Diagnostic", silent = true })
vim.keymap.set("n", "[d", diagnostic_goto(-1), { desc = "Prev Diagnostic", silent = true })
vim.keymap.set("n", "]e", diagnostic_goto(1, "ERROR"), { desc = "Next Error", silent = true })
vim.keymap.set("n", "[e", diagnostic_goto(-1, "ERROR"), { desc = "Prev Error", silent = true })
vim.keymap.set("n", "]w", diagnostic_goto(1, "WARN"), { desc = "Next Warning", silent = true })
vim.keymap.set("n", "[w", diagnostic_goto(-1, "WARN"), { desc = "Prev Warning", silent = true })

vim.keymap.set(
  "n",
  "<leader>uf",
  require("fredrik.utils.toggle").toggle_manual_folding,
  { desc = "Toggle manual folding", silent = true }
)

vim.keymap.set(
  "n",
  "<leader>us",
  require("fredrik.utils.shada").remove_shada_files,
  { desc = "Remove shada files", silent = true }
)

function M.setup_trouble_keymaps()
  return {
    {
      "<leader>xx",
      "<cmd>Trouble diagnostics toggle<cr>",
      desc = "Diagnostics (Trouble)",
    },
    {
      "<leader>xX",
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    -- {
    --   "<leader>cs",
    --   "<cmd>:Neotree document_symbols<cr>",
    --   desc = "Symbols (Neotree)",
    -- },
    {
      "<leader>cl",
      "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
      desc = "LSP Definitions / references / ... (Trouble)",
    },
    {
      "<leader>xL",
      "<cmd>Trouble loclist toggle<cr>",
      desc = "Location List (Trouble)",
    },
    {
      "<leader>xQ",
      "<cmd>Trouble qflist toggle<cr>",
      desc = "Quickfix List (Trouble)",
    },
  }
end

function M.setup_lsp_autocmd_keymaps(buf)
  local map = function(keys, func, desc)
    vim.keymap.set("n", keys, func, { buffer = buf, desc = "LSP: " .. desc, nowait = true })
  end

  -- Rename the variable under your cursor
  --  Most Language Servers support renaming across files, etc.
  map("<leader>cr", vim.lsp.buf.rename, "[C]ode [R]ename")

  map("<leader>cR", Snacks.rename.rename_file, "[C]ode [R]ename")

  -- Execute a code action, usually your cursor needs to be on top of an error
  -- or a suggestion from your LSP for this to activate.
  map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

  -- Show the available code actions for the word under your cursor
  map("<leader>cc", vim.lsp.codelens.run, "Run Codelens")
  -- map("<leader>cC", vim.lsp.codelens.refresh, "Refresh & Display Codelens") -- only needed if not using autocmd

  -- Opens a popup that displays documentation about the word under your cursor
  --  See `:help K` for why this keymap
  map("K", vim.lsp.buf.hover, "Hover Documentation")

  -- WARN: This is not Goto Definition, this is Goto Declaration.
  --  For example, in C this would take you to the header
  map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
end

function M.setup_typescript_lsp_keymaps()
  return {
    {
      "gS",
      function()
        require("vtsls").commands.goto_source_definition(0)
      end,
      desc = "Goto Source Definition",
    },
    {
      "gR",
      function()
        require("vtsls").commands.file_references(0)
      end,
      desc = "File References",
    },
    {
      "<leader>co",
      function()
        require("vtsls").commands.organize_imports(0)
      end,
      desc = "Organize Imports",
    },
    {
      "<leader>cM",
      function()
        require("vtsls").commands.add_missing_imports(0)
      end,
      desc = "Add missing imports",
    },
    {
      "<leader>cu",
      function()
        require("vtsls").commands.remove_unused_imports(0)
      end,
      desc = "Remove unused imports",
    },
    {
      "<leader>cD",
      function()
        require("vtsls")
      end,
      desc = "Fix all diagnostics",
    },
    {
      "<leader>cV",
      function()
        require("vtsls").commands.select_ts_version(0)
      end,
      desc = "Select TS workspace version",
    },
  }
end

function M.setup_blink_cmp_keymaps()
  -- https://cmp.saghen.dev/configuration/keymap
  return {

    ["<C-e>"] = { "hide", "fallback" },
    ["<CR>"] = { "accept", "fallback" },

    ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },

    ["<Up>"] = { "select_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },

    ["<C-u>"] = { "scroll_documentation_up", "fallback" },
    ["<C-d>"] = { "scroll_documentation_down", "fallback" },

    ["<C-space>"] = { "show" },

    -- C-k toggles signature
  }
end

function M.setup_blink_cmdline_keymaps()
  return {
    ["<Up>"] = { "select_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },
  }
end

function M.setup_luasnip_keymaps()
  return {
    {
      "<tab>",
      function()
        return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
      end,
      expr = true,
      silent = true,
      mode = "i",
    },
    {
      "<tab>",
      function()
        require("luasnip").jump(1)
      end,
      mode = "s",
    },
    {
      "<s-tab>",
      function()
        require("luasnip").jump(-1)
      end,
      mode = { "i", "s" },
    },
  }
end

function M.setup_coderunner_keymaps()
  return {
    { "<leader>rf", ":RunFile term<CR>", desc = "Run file" },
  }
end

function M.setup_snacks_keymaps()
  -- NOTE: Snacks is a global; _G.Snacks = M
  return {
    -- misc
    {
      "<leader><leader>",
      function()
        ---@type snacks.picker.smart.Config
        local opts = {
          multi = { "buffers", "files" },
          hidden = true,
          ignored = true,
          exclude = { "*.pb.go", ".venv/*", ".mypy_cache/*", ".repro/*" },
          formatters = {
            file = {
              truncate = 100,
            },
          },
        }
        Snacks.picker.smart(opts)
      end,
      desc = "Files",
    },
    {
      "<leader>/",
      function()
        ---@class snacks.picker.grep.Config: snacks.picker.proc.Config
        local opts = { hidden = true, ignored = true, exclude = { "*.pb.go", ".venv/*", ".mypy_cache/*", ".repro/*" } }
        Snacks.picker.grep(opts)
      end,
      desc = "Grep",
    },
    {
      "<leader>:",
      function()
        Snacks.picker.command_history()
      end,
      desc = "Command History",
    },
    {
      "<leader>e",
      function()
        Snacks.explorer.open({ hidden = true, ignored = true, exclude = { ".DS_Store" } })
      end,
      desc = "Explorer",
    },
    {
      "<leader>E",
      function()
        Snacks.explorer.reveal({ hidden = true, ignored = true })
      end,
      desc = "Explorer (reveal buffer)",
    },
    {
      "<leader>gg",
      function()
        Snacks.lazygit.open()
      end,
      desc = "LazyGit",
    },
    {
      "<leader>gdd",
      function()
        Snacks.picker.git_diff()
      end,
      desc = "Git Diff (HEAD)",
    },
    {
      "<leader>gdD",
      function()
        ---@class snacks.picker.git.diff.Config: snacks.picker.git.Config
        local opts = { base = "origin" }
        Snacks.picker.git_diff(opts)
      end,
      desc = "Git Diff (origin)",
    },
    {
      "<leader>uz",
      function()
        Snacks.zen.zen()
      end,
      desc = "Toggle Zen mode",
    },
    {
      "<leader>uZ",
      function()
        Snacks.zen.zen()
      end,
      desc = "Toggle Zen mode",
    },
    {
      "<leader>un",
      function()
        Snacks.notifier.show_history()
      end,
      desc = "Toggle notification history",
    },
    {
      "<leader>D",
      function()
        Snacks.dashboard.open()
      end,
      desc = "Dashboard",
    },

    -- lsp
    {
      "gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "Goto Definition",
    },
    {
      "gD",
      function()
        Snacks.picker.lsp_declarations()
      end,
      desc = "Goto Declaration",
    },
    {
      "gr",
      function()
        Snacks.picker.lsp_references()
      end,
      nowait = true,
      desc = "References",
    },
    {
      "gI",
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "Goto Implementation",
    },
    {
      "gt",
      function()
        Snacks.picker.lsp_type_definitions()
      end,
      desc = "Goto T[y]pe Definition",
    },
    {
      "<leader>ss",
      function()
        Snacks.picker.lsp_symbols()
      end,
      desc = "[s]earch LSP [s]ymbols",
    },
    {
      "<leader>sS",
      function()
        Snacks.picker.lsp_workspace_symbols()
      end,
      desc = "[s]earch LSP [S]ymbols (workspace)",
    },

    -- search
    {
      '<leader>s"',
      function()
        Snacks.picker.registers()
      end,
      desc = '[s]earch ["]registers',
    },
    {
      "<leader>sh",
      function()
        Snacks.picker.help()
      end,
      desc = "[s]earch [h]elp pages",
    },

    {
      "<leader>sa",
      function()
        Snacks.picker.autocmds()
      end,
      desc = "[s]earch [a]utocommands",
    },
    {
      "<leader>sb",
      function()
        Snacks.picker.buffers()
      end,
      desc = "[s]earch opened [b]uffers",
    },
    {
      "<leader>sc",
      function()
        Snacks.picker.commands()
      end,
      desc = "[s]earch [c]ommands",
    },
    {
      "<leader>sH",
      function()
        Snacks.picker.highlights()
      end,
      desc = "[s]earch [H]ighlight groups",
    },
    {
      "<leader>sk",
      function()
        Snacks.picker.keymaps()
      end,
      desc = "[s]earch [k]ey maps",
    },
    {
      "<leader>sM",
      function()
        Snacks.picker.man()
      end,
      desc = "[s]earch [M]an pages",
    },
    {
      "<leader>sm",
      function()
        Snacks.picker.marks()
      end,
      desc = "[s]earch [m]arks",
    },
    {
      "<leader>sn",
      function()
        Snacks.picker.notifications()
      end,
      desc = "[s]earch [n]notifications",
    },
    {
      "<leader>sj",
      function()
        Snacks.picker.jumps()
      end,
      desc = "[s]earch [j]umplist",
    },
    {
      "<leader>sp",
      function()
        ---@class snacks.picker.projects.Config: snacks.picker.Config
        local opts = { dev = { "~/code/public", "~/code/work/private", "~/code/work/public" } }
        Snacks.picker.projects(opts)
      end,
      desc = "[s]earch [p]rojects",
    },
    {
      "<leader>sq",
      function()
        Snacks.picker.qflist()
      end,
      desc = "[s]earch [q]uickfix List",
    },
    {
      "<leader>sF",
      function()
        Snacks.picker.recent()
      end,
      desc = "[s]earch recent [F]iles",
    },
    {
      "<leader>sd",
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = "[s]earch [d]ocument diagnostics",
    },
    {
      "<leader>sD",
      function()
        Snacks.picker.diagnostics()
      end,
      desc = "[s]earch workspace [D]iagnostics",
    },
    {
      "<leader>sL",
      function()
        Snacks.picker.lazy()
      end,
      desc = "[s]earch [L]azy plugins",
    },
    {
      "<leader>st",
      function()
        Snacks.picker.todo_comments()
      end,
      desc = "[s]earch [t]odo",
    },
    {
      "<leader>sT",
      function()
        Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
      end,
      desc = "[s]earch [T]odo/Fix/Fixme",
    },
    {
      "<leader>sz",
      function()
        Snacks.picker.zoxide()
      end,
      desc = "[s]earch with [z]oxide",
    },

    -- git
    {
      "<leader>sgc",
      function()
        Snacks.picker.git_log()
      end,
      desc = "[s]earch [g]it [c]ommit log",
    },
    {
      "<leader>sgf",
      function()
        Snacks.picker.git_log_file()
      end,
      desc = "[s]earch [g]it commit log [f]ile",
    },
    {
      "<leader>sgs",
      function()
        Snacks.picker.git_status()
      end,
      desc = "[s]earch [g]it [s]tatus changes",
    },
    {
      "<leader>sgb",
      function()
        Snacks.picker.git_branches()
      end,
      desc = "[s]earch [g]it [b]ranches",
    },

    -- custom pickers
    {
      "<leader>sP",
      function()
        require("fredrik.utils.snacks_pickers").pull_requests()
      end,
      desc = "[s]earch [P]ull Requests",
    },
    {
      "<leader>sl",
      function()
        require("fredrik.utils.snacks_pickers").neovim_logs()
      end,
      desc = "[s]earch [l]ogs",
    },
  }
end

function M.setup_yanky_keymaps()
  return {
    {
      "<leader>p",
      function()
        Snacks.picker.yanky()
      end,
      desc = "Yanky history",
    },
  }
end

function M.setup_gitsigns_keymaps(bufnr)
  local gs = package.loaded.gitsigns

  vim.keymap.set("n", "]h", function()
    if vim.wo.diff then
      return "]c"
    end
    vim.schedule(function()
      gs.nav_hunk("next")
    end)
    return "<Ignore>"
  end, { expr = true })

  vim.keymap.set("n", "[h", function()
    if vim.wo.diff then
      return "[c"
    end
    vim.schedule(function()
      gs.nav_hunk("prev")
    end)
    return "<Ignore>"
  end, { expr = true })

  vim.keymap.set({ "n", "v" }, "<leader>ghb", function()
    local default_branch = require("fredrik.utils.git").get_default_branch()
    vim.cmd("Gitsigns change_base " .. default_branch)
  end, { buffer = bufnr, silent = false, noremap = true, desc = "change [b]ase to default branch" })

  vim.keymap.set(
    { "n", "v" },
    "<leader>ghs",
    ":Gitsigns stage_hunk<CR>",
    { buffer = bufnr, silent = true, noremap = true, desc = "[s]tage hunk" }
  )
  vim.keymap.set(
    { "n", "v" },
    "<leader>ghS",
    ":Gitsigns stage_buffer<CR>",
    { buffer = bufnr, silent = true, noremap = true, desc = "[S]tage buffer" }
  )
  vim.keymap.set(
    "n",
    "<leader>ghu",
    gs.undo_stage_hunk,
    { buffer = bufnr, silent = true, noremap = true, desc = "[u]ndo stage hunk" }
  )
  vim.keymap.set(
    "n",
    "<leader>ghr",
    gs.reset_hunk,
    { buffer = bufnr, silent = true, noremap = true, desc = "[r]eset hunk" }
  )
  vim.keymap.set(
    "n",
    "<leader>gbb",
    gs.blame,
    { buffer = bufnr, silent = true, noremap = true, desc = "[b]lame on the side" }
  )
end

-- Helper function to get hunk range at cursor
local function get_hunk_range_at_cursor()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local buf_data = MiniDiff.get_buf_data(0)

  if not buf_data or not buf_data.hunks then
    return line, line
  end

  for _, hunk in ipairs(buf_data.hunks) do
    local hunk_start = hunk.buf_start
    local hunk_end = hunk.buf_start + math.max(0, hunk.buf_count - 1)

    if line >= hunk_start and line <= hunk_end then
      return hunk_start, hunk_end
    end
  end

  -- Fallback to single line if no hunk found
  return line, line
end

function M.setup_mini_diff_keymaps()
  return {
    {
      "<leader>gdO",
      function()
        require("mini.diff").toggle_overlay(0)
      end,
      desc = "Toggle mini.diff overlay",
    },
    {
      "<leader>ghr",
      function()
        local start_line, end_line = get_hunk_range_at_cursor()
        require("mini.diff").do_hunks(0, "reset", { line_start = start_line, line_end = end_line })
      end,
      desc = "Reset hunk",
    },
    {
      "<leader>ghs",
      function()
        local start_line, end_line = get_hunk_range_at_cursor()
        require("mini.diff").do_hunks(0, "apply", { line_start = start_line, line_end = end_line })
      end,
      desc = "Stage hunk",
    },
    {
      "<leader>ghy",
      function()
        local start_line, end_line = get_hunk_range_at_cursor()
        require("mini.diff").do_hunks(0, "yank", { line_start = start_line, line_end = end_line })
      end,
      desc = "Yank hunk",
    },
    {
      "<leader>ghb",
      function()
        local default_branch = require("fredrik.utils.git").get_default_branch()
        local file = vim.api.nvim_buf_get_name(0)
        local relative_path = vim.fn.fnamemodify(file, ":~:.")

        -- Get content from the default branch
        local content = vim.fn.system("git show " .. default_branch .. ":" .. relative_path)

        if vim.v.shell_error == 0 then
          local lines = vim.split(content, "\n")
          require("mini.diff").set_ref_text(0, lines)
          vim.notify("Diff base changed to " .. default_branch, vim.log.levels.INFO)
        else
          vim.notify("Could not get file from " .. default_branch, vim.log.levels.ERROR)
        end
      end,
      desc = "Change base to default branch",
    },
    {
      "<leader>ghB",
      function()
        require("mini.diff").set_ref_text(0, {})
        vim.notify("Diff base reset to Git index", vim.log.levels.INFO)
      end,
      desc = "Reset base to Git index",
    },
  }
end

function M.setup_git_blame_keymaps()
  return {
    -- toggle needs to be called twice; https://github.com/f-person/git-blame.nvim/issues/16
    { "<leader>gbl", ":GitBlameToggle<CR>", desc = "Blame line (toggle)", silent = true },
    { "<leader>gbs", ":GitBlameCopySHA<CR>", desc = "Copy SHA", silent = true },
    { "<leader>gbc", ":GitBlameCopyCommitURL<CR>", desc = "Copy commit URL", silent = true },
    { "<leader>gbf", ":GitBlameCopyFileURL<CR>", desc = "Copy file URL", silent = true },
    { "<leader>gbo", ":GitBlameOpenFileURL<CR>", desc = "Open file URL", silent = true },
  }
end

function M.setup_diffview_keymaps()
  return {
    -- use [c and [c to navigate diffs (vim built in), see :h jumpto-diffs
    -- use ]x and [x to navigate conflicts
    { "<leader>gdq", ":DiffviewClose<CR>", desc = "Close Diffview tab" },
    { "<leader>gdh", ":DiffviewFileHistory %<CR>", desc = "File history" },
    { "<leader>gdH", ":DiffviewFileHistory<CR>", desc = "Repo history" },
    { "<leader>gdm", ":DiffviewOpen<CR>", desc = "Solve merge conflicts" },
    {
      "<leader>gdo",
      ":DiffviewOpen " .. require("fredrik.utils.git").get_default_branch() .. "<cr>",
      desc = "DiffviewOpen against default branch",
    },
    { "<leader>gdt", ":DiffviewOpen<CR>", desc = "DiffviewOpen this" },
    {
      "<leader>gdp",
      function()
        local default_branch = require("fredrik.utils.git").get_default_branch()
        vim.cmd(":DiffviewOpen origin/" .. default_branch .. "...HEAD --imply-local")
      end,
      desc = "Review current PR",
    },
    {
      "<leader>gdP",
      function()
        local default_branch = require("fredrik.utils.git").get_default_branch()
        return vim.cmd(
          ":DiffviewFileHistory --range=origin/" .. default_branch .. "...HEAD --right-only --no-merges --reverse"
        )
      end,
      desc = "Review current PR (per commit)",
    },
  }
end

function M.setup_neotest_keymaps()
  return {
    {
      "<leader>ta",
      function()
        require("neotest").run.attach()
      end,
      desc = "Attach",
    },
    {
      "<leader>tf",
      function()
        require("neotest").run.run(vim.fn.expand("%"))
      end,
      desc = "Run File",
    },
    {
      "<leader>tA",
      function()
        require("neotest").run.run(vim.uv.cwd())
      end,
      desc = "Run All Test Files",
    },
    {
      "<leader>tT",
      function()
        require("neotest").run.run({ suite = true })
      end,
      desc = "Run Test Suite",
    },
    {
      "<leader>tn",
      function()
        require("neotest").run.run()
      end,
      desc = "Run Nearest",
    },
    {
      "<leader>tl",
      function()
        require("neotest").run.run_last()
      end,
      desc = "Run Last",
    },
    {
      "<leader>ts",
      function()
        require("neotest").summary.toggle()
      end,
      desc = "Toggle Summary",
    },
    {
      "<leader>to",
      function()
        require("neotest").output.open({ enter = true, auto_close = true })
      end,
      desc = "Show Output",
    },
    {
      "<leader>tO",
      function()
        require("neotest").output_panel.toggle()
      end,
      desc = "Toggle Output Panel",
    },
    {
      "<leader>tt",
      function()
        require("neotest").run.stop()
      end,
      desc = "Terminate",
    },
    {
      "<leader>td",
      function()
        -- vim.cmd("Neotree close")
        require("neotest").summary.close()
        require("neotest").output_panel.close()
        require("neotest").run.run({ suite = false, strategy = "dap" })
      end,
      desc = "Debug nearest test",
    },
    {
      "<leader>tD",
      function()
        -- vim.cmd("Neotree close")
        require("neotest").summary.close()
        require("neotest").output_panel.close()
        require("neotest").run.run({ vim.fn.expand("%"), suite = false, strategy = "dap" })
      end,
      desc = "Debug current file",
    },

    -- -- map_normal_mode("<leader>td", ':lua require("neotest").run.run({vim.fn.expand("%"), strategy = "dap"})<CR>', "[t]est [d]ebug Nearest")
    -- map_normal_mode("<leader>td", ':lua require("neotest").run.run({ strategy = "dap" })<CR>', "[t]est [d]ebug Nearest")
    -- map_normal_mode("<leader>tg", function()
    --   -- FIXME: https://github.com/nvim-neotest/neotest-go/issues/12
    --   -- Depends on "leoluz/nvim-dap-go"
    --   require("dap-go").debug_test()
    -- end, "[d]ebug [g]o (nearest test)")
  }
end

function M.setup_coverage_keymaps()
  vim.keymap.set("n", "<leader>tc", ":Coverage<CR>", { desc = "[t]est [c]overage in gutter", silent = true })
  vim.keymap.set(
    "n",
    "<leader>tC",
    ":CoverageLoad<CR>:CoverageSummary<CR>",
    { desc = "[t]est [C]overage summary", silent = true }
  )
end

function M.setup_outline_keymaps()
  return {
    { "<leader>cs", "<cmd>Outline<CR>", desc = "Toggle outline" },
  }
end

function M.setup_dap_ui_keymaps()
  -- keymaps: https://github.com/mfussenegger/nvim-dap/blob/master/doc/dap.txt#L508
  -- NOTE: see e.g. :h nvim-dap-ui for help on *dapui.elements.stacks*, where o opens up a stack.
  return {
    {
      "<leader>du",
      function()
        require("dapui").toggle({})
      end,
      desc = "DAP UI",
    },

    {
      "<leader>de",
      function()
        require("dapui").eval()
      end,
      desc = "[d]ebug [e]valuate expression",
    },
  }
end

function M.setup_dap_keymaps()
  return {
    {
      "<leader>db",
      function()
        require("dap").toggle_breakpoint()
      end,
      desc = "toggle [d]ebug [b]reakpoint",
    },
    {
      "<leader>dB",
      function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end,
      desc = "[d]ebug [B]reakpoint",
    },
    {
      "<leader>dc",
      function()
        require("dap").continue()
      end,
      desc = "[d]ebug [c]ontinue (start here)",
    },
    {
      "<leader>dC",
      function()
        require("dap").run_to_cursor()
      end,
      desc = "[d]ebug [C]ursor",
    },
    {
      "<leader>dg",
      function()
        require("dap").goto_()
      end,
      desc = "[d]ebug [g]o to line",
    },
    {
      "<leader>do",
      function()
        require("dap").step_over()
      end,
      desc = "[d]ebug step [o]ver",
    },
    {
      "<leader>dO",
      function()
        require("dap").step_out()
      end,
      desc = "[d]ebug step [O]ut",
    },
    {
      "<leader>di",
      function()
        require("dap").step_into()
      end,
      desc = "[d]ebug [i]nto",
    },
    {
      "<leader>dj",
      function()
        require("dap").down()
      end,
      desc = "[d]ebug [j]ump down",
    },
    {
      "<leader>dk",
      function()
        require("dap").up()
      end,
      desc = "[d]ebug [k]ump up",
    },
    {
      "<leader>dl",
      function()
        require("dap").run_last()
      end,
      desc = "[d]ebug [l]ast",
    },
    {
      "<leader>dp",
      function()
        require("dap").pause()
      end,
      desc = "[d]ebug [p]ause",
    },
    {
      "<leader>dr",
      function()
        require("dap").repl.toggle()
      end,
      desc = "[d]ebug [r]epl",
    },
    {
      "<leader>dR",
      function()
        require("dap").clear_breakpoints()
      end,
      desc = "[d]ebug [R]emove breakpoints",
    },
    {
      "<leader>ds",
      function()
        require("dap").session()
      end,
      desc = "[d]ebug [s]ession",
    },
    {
      "<leader>dS",
      function()
        require("dap").restart()
      end,
      desc = "[d]ebug re[S]tart",
    },
    {
      "<leader>dt",
      function()
        require("dap").terminate()
      end,
      desc = "[d]ebug [t]erminate",
    },
    {
      "<leader>dw",
      function()
        require("dap.ui.widgets").hover()
      end,
      desc = "[d]ebug [w]idgets",
    },
  }
end

function M.setup_osv_keymaps()
  return {
    {
      "<leader>dLl",
      function()
        require("osv").launch({ port = 8086 })
        require("osv").stop()
      end,
      desc = "[d]ebug [L]ua: [l]aunch server",
    },
    {
      "<leader>dLr",
      function()
        require("osv").run_this() -- current buffer
      end,
      desc = "[d]ebug [L]ua: [r]un this",
    },
  }
end

function M.setup_grug_far_keymaps()
  return {
    { "<leader>sr", ":GrugFar<cr>", desc = "[s]earch and [r]eplace (grug-far)" },
    { "<leader>sr", ":GrugFarWithin<cr>", desc = "[s]earch and [r]eplace in selection (grug-far)", mode = "v" },
  }
end

function M.setup_rip_substitute_keymaps()
  return {
    {
      "<leader>sR",
      function()
        require("rip-substitute").sub()
      end,
      mode = { "n", "x" },
      desc = "[s]earch [R]eplace (rip-substitute)",
    },
  }
end

function M.setup_terminal_keymaps()
  -- Both <C-/> and <C-_> are mapped due to the way control characters are interpreted by terminal emulators.
  -- ASCII value of '/' is 47, and of '_' is 95. When <C-/> is pressed, the terminal sends (47 - 64) which wraps around to 111 ('o').
  -- When <C-_> is pressed, the terminal sends (95 - 64) which is 31. Hence, both key combinations need to be mapped.

  -- <C-/> toggles the floating terminal
  local ctrl_slash = "<C-/>"
  local ctrl_underscore = "<C-_>"

  -- <C-A-/> toggles the split terminal
  local ctrl_alt_slash = "<C-A-/>"
  local ctrl_alt_underscore = "<C-A-_>"

  -- <Esc><Esc> in terminal mode sends <C-\><C-n> to exit terminal mode, see :h term
  vim.api.nvim_set_keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { noremap = true })

  local floating_term_cmd = function()
    local cmd = { "zsh" }
    local opts = { cwd = vim.fn.getcwd() }
    Snacks.terminal.toggle(cmd, opts)
  end

  return {
    {
      ctrl_alt_slash,
      require("fredrik.utils.terminal").toggle_split_terminal,
      mode = { "n", "i", "t", "v" },
      desc = "Toggle split terminal",
    },
    {
      ctrl_alt_underscore,
      require("fredrik.utils.terminal").toggle_split_terminal,
      mode = { "n", "i", "t", "v" },
      desc = "Toggle split terminal",
    },

    { ctrl_slash, floating_term_cmd, mode = { "n", "i", "t", "v" }, desc = "Toggle floating terminal" },
    { ctrl_underscore, floating_term_cmd, mode = { "n", "i", "t", "v" }, desc = "Toggle floating terminal" },

    -- NOTE: Snacks.terminal handles closing the terminal, so these are not needed as long as Snacks.terminal is used.
    -- { ctrl_slash, "<cmd>close<cr>", mode = { "t" }, desc = "Hide Terminal" },
    -- { ctrl_underscore, "<cmd>close<cr>", mode = { "t" }, desc = "which_key_ignore" },
  }
end

function M.setup_conform_keymaps()
  vim.keymap.set(
    "n",
    "<leader>uf",
    require("fredrik.utils.toggle").toggle_formatting,
    { desc = "Toggle auto-formatting", silent = true }
  )
end

function M.setup_lsp_keymaps()
  vim.keymap.set(
    "n",
    "<leader>uh",
    require("fredrik.utils.toggle").toggle_inlay_hints,
    { desc = "Toggle inlay hints", silent = true }
  )
end

function M.setup_showkeys_keymaps()
  return {
    { "<leader>uk", ":ShowkeysToggle<CR>", desc = "Show keys (toogle)" },
  }
end

function M.setup_minimap_keymaps()
  return {
    {
      "<leader>um",
      function()
        vim.cmd("Neominimap Toggle")
      end,
      desc = "Toggle Mini map",
    },
  }
end

function M.setup_markdown_keymaps()
  return {
    {
      "<Leader>uM",
      function()
        local m = require("render-markdown")
        local enabled = require("render-markdown.state").enabled
        if enabled then
          m.disable()
          vim.cmd("setlocal conceallevel=0")
        else
          m.enable()
          vim.cmd("setlocal conceallevel=2")
        end
      end,
      desc = "Toggle markdown render",
    },
  }
end

function M.setup_diagnostics_keymaps()
  vim.keymap.set("n", "<leader>ud", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  end, { desc = "Toggle diagnostics", silent = true })
end

function M.setup_winshift_keymaps()
  return {
    { "<leader>ww", "<cmd>WinShift<CR>", desc = "[w]inshift (shift + arrows)" },
  }
end

function M.setup_maximizer_keymaps()
  return {
    { "<leader>wm", "<cmd>MaximizerToggle<CR>", desc = "[w]indow [m]aximize toggle" },
    { "<C-w>m", "<cmd>MaximizerToggle<CR>", desc = "Window maximize toggle" },
  }
end

function M.setup_obsidian_keymaps(obsidian_vars)
  return {
    { "<leader>ns", "<cmd>Obsidian search<cr>", desc = "[N]otes: [s]earch text" },
    { "<leader>nf", "<cmd>Obsidian quick_switch<cr>", desc = "[N]otes: search [f]ilenames" },
    { "<leader>nn", "<cmd>Obsidian new<cr>", desc = "[N]otes: [n]new" },
    {
      "<leader>nS",
      function()
        vim.cmd("tabnew " .. obsidian_vars.scratchpad_path)
      end,
      desc = "[N]otes: [S]cratchpad",
    },
    { "<leader>nt", "<cmd>Obsidian new_from_template<cr>", desc = "[N]otes: new [m]eeting agenda from template" },
  }
end

function M.setup_whichkey(wk)
  wk.add({
    { "<leader><tab>", group = "tab" },
    { "<leader>a", group = "ai" },
    { "<leader>c", group = "code" },
    { "<leader>d", group = "debug" },
    { "<leader>dL", group = "debug lua" },
    { "<leader>b", group = "buffer" },
    { "<leader>g", group = "git" },
    { "<leader>gb", group = "blame" },
    { "<leader>gd", group = "diffview" },
    { "<leader>gh", group = "hunks" },
    { "<leader>n", group = "notes" },
    { "<leader>r", group = "run" },
    { "<leader>s", group = "search" },
    { "<leader>sg", group = "git" },
    -- { "<leader>sn", group = "noice" },
    { "<leader>t", group = "test" },
    { "<leader>u", group = "ui" },
    { "<leader>x", group = "diagnostics/quickfix" },
    { "<leader>w", group = "windows", proxy = "<C-w>" },
    {
      "<leader>b",
      group = "buffers",
      expand = function()
        return require("which-key.extras").expand.buf()
      end,
    },
  })
end

function M.setup_whichkey_contextual()
  return {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  }
end

function M.setup_rest_keymaps()
  return {
    { "<leader>rr", "<Plug>RestNvim", desc = "Run REST request under cursor" },
  }
end

function M.setup_venv_selector_keymaps()
  return {
    { "<leader>vs", "<cmd>VenvSelect<cr>" },
    { "<leader>vc", "<cmd>VenvSelectCached<cr>" },
  }
end

function M.setup_sidekick_keymaps()
  return {
    {
      "<tab>",
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if not require("sidekick").nes_jump_or_apply() then
          return "<Tab>" -- fallback to normal tab
        end
      end,
      expr = true,
      desc = "Goto/Apply Next Edit Suggestion",
    },
    {
      "<c-.>",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick Toggle",
      mode = { "n", "t", "i", "x" },
    },
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select()
      end,
      -- Or to select only installed tools:
      -- require("sidekick.cli").select({ filter = { installed = true } })
      desc = "Select CLI",
    },
    {
      "<leader>ad",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Detach a CLI Session",
    },
    {
      "<leader>at",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>af",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Send File",
    },
    {
      "<leader>av",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<leader>ap",
      function()
        require("sidekick.cli").prompt()
      end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
    -- Example of a keybinding to open Claude directly
    {
      "<leader>ac",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Sidekick Toggle Claude",
    },
  }
end

function M.setup_copilot_lsp_keymaps()
  vim.keymap.set("n", "<tab>", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local state = vim.b[bufnr].nes_state
    if state then
      -- Try to jump to the start of the suggestion edit.
      -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
      local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
        or (require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit())
      return nil
    else
      -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
      return "<C-i>"
    end
  end, { desc = "Accept Copilot NES suggestion", expr = true })
  -- Clear copilot suggestion with Esc if visible, otherwise preserve default Esc behavior
  vim.keymap.set("n", "<esc>", function()
    if not require("copilot-lsp.nes").clear() then
      -- fallback to other functionality
    end
  end, { desc = "Clear Copilot suggestion or fallback" })
end

function M.setup_copilot_keymaps()
  return {
    -- Suggestions (insert mode)
    {
      "<M-l>",
      function()
        require("copilot.suggestion").accept()
      end,
      desc = "Copilot: Accept suggestion",
      mode = "i",
    },
    {
      "<M-]>",
      function()
        require("copilot.suggestion").next()
      end,
      desc = "Copilot: Next suggestion",
      mode = "i",
    },
    {
      "<M-[>",
      function()
        require("copilot.suggestion").prev()
      end,
      desc = "Copilot: Previous suggestion",
      mode = "i",
    },
  }
end

function M.setup_substitute_keymaps()
  return {
    {
      mode = { "n" },
      "s",
      function()
        require("substitute").operator()
      end,
      desc = "[s]ubstitute",
    },
    {
      mode = { "n" },
      "ss",
      function()
        require("substitute").line()
      end,
      desc = "[s]ubstitute line",
    },
    {
      mode = { "n" },
      "S",
      function()
        require("substitute").eol()
      end,
      desc = "[s]ubstitute eol",
    },
    {
      mode = { "x" },
      "x",
      function()
        require("substitute").visual()
      end,
      desc = "[s]ubstitute visual selection",
    },
  }
end

return M
