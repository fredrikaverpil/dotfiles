M = {}

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
vim.keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
vim.keymap.set("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })
vim.keymap.set("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
vim.keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })

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

local function map_normal_mode(keys, func, desc)
  -- default values:
  -- noremap: false
  -- silent: false
  vim.keymap.set("n", keys, func, { desc = desc, noremap = false, silent = true })
end

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
        require("vtsls").commands.fix_all(0)
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
  return {
    ["<C-e>"] = { "hide", "fallback" },
    ["<CR>"] = { "accept", "fallback" },

    ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },

    ["<Up>"] = { "select_prev", "fallback" },
    ["<Down>"] = { "select_next", "fallback" },

    ["<C-u>"] = { "scroll_documentation_up", "fallback" },
    ["<C-d>"] = { "scroll_documentation_down", "fallback" },
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

function M.setup_telescope_keymaps()
  --- @param set_cwd boolean
  local function open_file_in_other_project(set_cwd)
    vim.g.project_set_cwd = set_cwd
    require("telescope").extensions.project.project({ display_type = "full", hide_workspace = true })
  end

  return {
    {
      "<leader>sf",
      function()
        open_file_in_other_project(false)
      end,
      desc = "[s]earch [f]ile (in projects)",
    },

    -- yank
    -- NOTE: reminder;
    -- Use `vep` to replace current a word with a yank.
    -- Use `Vp` to replace a line with a yank.
    {
      "<leader>p",
      function()
        require("telescope").extensions.yank_history.yank_history({})
      end,
      desc = "Yanky history",
    },

    -- search
    { "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "[s]earch [o]ptions" },
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
        local opts = {
          multi = { "buffers", "files" },
          hidden = true,
          ignored = true,
          exclude = { "*.pb.go", ".venv/*", ".mypy_cache/*", ".repro/*" },
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
      "<leader>e",
      function()
        Snacks.explorer.open({ hidden = true, ignored = true })
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
      "<leader>sn",
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
      "<leader>sj",
      function()
        Snacks.picker.jumps()
      end,
      desc = "[s]earch [j]umplist",
    },
    {
      "<leader>sp",
      function()
        Snacks.picker.zoxide()
      end,
      desc = "[s]earch [p]rojects (zoxide)",
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
      desc = "[s]earch [D]iagnostics",
    },
    {
      "<leader>sl",
      function()
        Snacks.picker.lazy()
      end,
      desc = "[s]earch [l]azy plugins",
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

    -- git
    {
      "<leader>sgl",
      function()
        Snacks.picker.git_log()
      end,
      desc = "[s]earch [g]it commit [l]og",
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

  vim.keymap.set(
    { "n", "v" },
    "<leader>ghb",
    ":Gitsigns change_base main",
    { buffer = bufnr, silent = false, noremap = true, desc = "change [b]ase" }
  )
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

function M.setup_neogit_keymaps()
  local function open_in_split()
    require("neogit").open({ kind = "split" })
  end

  vim.keymap.set("n", "<leader>gn", open_in_split, { silent = true, noremap = true, desc = "Neogit" })
  vim.keymap.set("n", "<leader>gp", ":Neogit pull<CR>", { silent = true, noremap = true, desc = "[g]it [p]ull" })
  vim.keymap.set("n", "<leader>gP", ":Neogit push<CR>", { silent = true, noremap = true, desc = "[g]it [P]ush" })
  -- NOTE: see Telescope git_... commands set by setup_telescope_keymaps
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
    {
      "<leader>gdc",
      function()
        local default_branch = require("fredrik.utils.git").get_default_branch()
        vim.cmd(":DiffviewOpen origin/" .. default_branch .. "...HEAD")
      end,
      desc = "Compare commits",
    },
    { "<leader>gdq", ":DiffviewClose<CR>", desc = "Close Diffview tab" },
    { "<leader>gdh", ":DiffviewFileHistory %<CR>", desc = "File history" },
    { "<leader>gdH", ":DiffviewFileHistory<CR>", desc = "Repo history" },
    { "<leader>gdm", ":DiffviewOpen<CR>", desc = "Solve merge conflicts" },
    { "<leader>gdo", ":DiffviewOpen main", desc = "DiffviewOpen" },
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
  map_normal_mode("<leader>tc", ":Coverage<CR>", "[t]est [c]overage in gutter")
  map_normal_mode("<leader>tC", ":CoverageLoad<CR>:CoverageSummary<CR>", "[t]est [C]overage summary")
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

    { ctrl_slash, "<cmd>close<cr>", mode = { "t" }, desc = "Hide Terminal" },
    { ctrl_underscore, "<cmd>close<cr>", mode = { "t" }, desc = "which_key_ignore" },
  }
end

function M.setup_conform_keymaps()
  map_normal_mode("<leader>uf", require("fredrik.utils.toggle").toggle_formatting, "Toggle auto-formatting")
end

function M.setup_lsp_keymaps()
  map_normal_mode("<leader>uh", require("fredrik.utils.toggle").toggle_inlay_hints, "Toggle inlay hints")
end

function M.setup_showkeys_keymaps()
  return {
    { "<leader>uk", ":ShowkeysToggle<CR>", desc = "Show keys (toogle)" },
  }
end

function M.setup_minimap_keymaps()
  return {
    { "<Leader>um", "<cmd>Neominimap toggle<CR>", desc = "Toggle Mini map" },
    -- { "<leader>nt", "<cmd>Neominimap toggle<cr>", desc = "Toggle minimap" },
    -- { "<leader>no", "<cmd>Neominimap on<cr>", desc = "Enable minimap" },
    -- { "<leader>nc", "<cmd>Neominimap off<cr>", desc = "Disable minimap" },
    -- { "<leader>nf", "<cmd>Neominimap focus<cr>", desc = "Focus on minimap" },
    -- { "<leader>nu", "<cmd>Neominimap unfocus<cr>", desc = "Unfocus minimap" },
    -- { "<leader>ns", "<cmd>Neominimap toggleFocus<cr>", desc = "Toggle focus on minimap" },
    -- { "<leader>nwt", "<cmd>Neominimap winToggle<cr>", desc = "Toggle minimap for current window" },
    -- { "<leader>nwr", "<cmd>Neominimap winRefresh<cr>", desc = "Refresh minimap for current window" },
    -- { "<leader>nwo", "<cmd>Neominimap winOn<cr>", desc = "Enable minimap for current window" },
    -- { "<leader>nwc", "<cmd>Neominimap winOff<cr>", desc = "Disable minimap for current window" },
    -- { "<leader>nbt", "<cmd>Neominimap bufToggle<cr>", desc = "Toggle minimap for current buffer" },
    -- { "<leader>nbr", "<cmd>Neominimap bufRefresh<cr>", desc = "Refresh minimap for current buffer" },
    -- { "<leader>nbo", "<cmd>Neominimap bufOn<cr>", desc = "Enable minimap for current buffer" },
    -- { "<leader>nbc", "<cmd>Neominimap bufOff<cr>", desc = "Disable minimap for current buffer" },
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
  map_normal_mode("<leader>ud", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
  end, "Toggle diagnostics")
end

function M.setup_winshift_keymaps()
  return {
    { "<leader>ww", "<cmd>WinShift<CR>", desc = "[w]inshift (shift + arrows)" },
  }
end

function M.setup_obsidian_keymaps(obsidian_vars)
  return {
    { "<leader>ns", "<cmd>ObsidianSearch<cr>", desc = "[N]otes: [s]earch text" },
    { "<leader>nf", "<cmd>ObsidianQuickSwitch<cr>", desc = "[N]otes: search [f]ilenames" },
    { "<leader>nn", "<cmd>ObsidianNew<cr>", desc = "[N]otes: [n]new" },
    { "<leader>nl", "<cmd>ObsidianQuickSwitch Learning.md<cr><cr>", desc = "[N]otes: [l]earning" },
    { "<leader>ng", "<cmd>ObsidianQuickSwitch Go.md<cr><cr>", desc = "[N]otes: [g]olang learning" },
    { "<leader>nv", "<cmd>ObsidianQuickSwitch Neovim config.md<cr><cr>", desc = "[N]otes: Neo[v]im todo" },

    {
      "<leader>nS",
      function()
        local client = require("obsidian").get_client()
        client:open_note(obsidian_vars.scratchpad_path)
      end,
      desc = "[N]otes: [S]cratchpad",
    },
    {
      "<leader>nm",
      function()
        local client = require("obsidian").get_client()
        -- client.dir is the vault path
        local note = client:create_note({
          title = "Meeting notes",
          dir = vim.fn.expand(obsidian_vars.notes_path),
          -- NOTE: if folder "templates" exist in $cwd,
          -- the template is expected to be found there.
          template = "meeting_notes",
        })
        client:open_note(note)
      end,
      desc = "[N]otes: new [m]eeting agenda from template",
    },
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
    { "<leader>sn", group = "noice" },
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

function M.setup_copilot_chat_keymaps(chat)
  return {
    {
      "<leader>aC",
      function()
        chat.toggle()
      end,
      desc = "Copilot Chat",
    },
  }
end

function M.setup_copilot_keymaps()
  return {
    { "<leader>ap", ":Copilot panel<CR>", desc = "Copilot panel" },
  }
end

function M.setup_codecompanion_keymaps()
  return {
    { "<leader>ac", ":CodeCompanionChat anthropic<CR>", desc = "Codecompanion: Claude" },
    { "<leader>ao", ":CodeCompanionChat openai<CR>", desc = "Codecompanion: OpenAI" },
    { "<leader>ag", ":CodeCompanionChat gemini<CR>", desc = "Codecompanion: Gemini" },
    { "<leader>ad", ":CodeCompanionChat deepseek<CR>", desc = "Codecompanion: DeepSeek" },
    { "<leader>al", ":CodeCompanionChat ollama<CR>", desc = "Codecompanion: Ollama" },

    { "<leader>at", ":CodeCompanionChat Toggle<CR>", desc = "Codecompanion toggle" },
    {
      "<leader>aS",
      function()
        local name = vim.fn.input("Save as: ")
        if name and name ~= "" then
          vim.cmd("CodeCompanionSave " .. name)
        end
      end,
      desc = "Codecompanion Save chat",
    },
    { "<leader>aL", ":CodeCompanionLoad<CR>", desc = "Codecompanion Load chat" },
    { "<leader>aP", ":CodeCompanionActions<CR>", desc = "Codecompanion Prompts" },
  }
end

return M
