M = {}

-- TODO: formatting toggle on <leader>uf
-- TODO: formatting on <leader>cf

-- TODO: Move to window using the <ctrl> hjkl keys
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window", silent = true, noremap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", silent = true, noremap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", silent = true, noremap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window", silent = true, noremap = true })

-- Resize windows using <ctrl> arrow keys
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height", silent = true })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height", silent = true })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width", silent = true })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width", silent = true })

-- Move Lines
vim.keymap.set("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down", silent = true })
vim.keymap.set("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up", silent = true })
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down", silent = true })
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up", silent = true })
vim.keymap.set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down", silent = true })
vim.keymap.set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up", silent = true })

-- Move between tmux windows (seems to work fine without these keymaps)
-- keys = {
--   { "n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", desc = "Navigate Left" },
--   { "n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", desc = "Navigate Down" },
--   { "n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", desc = "Navigate Up" },
--   { "n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Navigate Right" },
--   { "n", "<C-\\>", "<cmd>TmuxNavigatePrevious<CR>", desc = "Navigate Previous" },
-- },

-- buffers
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
-- vim.keymap.set("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
vim.keymap.set("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

-- tabs (disabled for now, use gt and gT instead)
-- vim.keymap.set("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab", silent = true })
-- vim.keymap.set("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab", silent = true })
-- vim.keymap.set("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab", silent = true })
-- vim.keymap.set("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab", silent = true })
-- vim.keymap.set("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab", silent = true })
-- vim.keymap.set("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab", silent = true })

-- Clear search with <esc>
vim.keymap.set({ "n", "i" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- save file
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- better indenting
vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })

-- Lazy.nvim
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- new file
vim.keymap.set("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- lists
vim.keymap.set("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
vim.keymap.set("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })
vim.keymap.set("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
vim.keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })

-- diagnostic
local function diagnostic_goto(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic", silent = true })
vim.keymap.set("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic", silent = true })
vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error", silent = true })
vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error", silent = true })
vim.keymap.set("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning", silent = true })
vim.keymap.set("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning", silent = true })

local function map_normal_mode(keys, func, desc)
  -- default values:
  -- noremap: false
  -- silent: false
  vim.keymap.set("n", keys, func, { desc = desc, noremap = false, silent = true })
end

function M.setup_trouble_keymaps()
  map_normal_mode("<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", "Document diagnostics (Trouble)")
  map_normal_mode("<leader>xX", "<cmd>TroubleToggle workspace_diagnostics<cr>", "Workspace diagnostics (Trouble)")
  -- vim.keymap.set("n", "<leader>xx", function() require("trouble").toggle() end)
  -- vim.keymap.set("n", "<leader>xw", function() require("trouble").toggle("workspace_diagnostics") end)
  -- vim.keymap.set("n", "<leader>xd", function() require("trouble").toggle("document_diagnostics") end)
  -- vim.keymap.set("n", "<leader>xq", function() require("trouble").toggle("quickfix") end)
  -- vim.keymap.set("n", "<leader>xl", function() require("trouble").toggle("loclist") end)
  -- vim.keymap.set("n", "gR", function() require("trouble").toggle("lsp_references") end)
end

function M.setup_lsp_keymaps(event)
  local map = function(keys, func, desc)
    vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
  end

  -- Jump to the definition of the word under your cursor.
  --  This is where a variable was first declared, or where a function is defined, etc.
  --  To jump back, press <C-t>.
  map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

  -- Find references for the word under your cursor.
  map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

  -- Jump to the implementation of the word under your cursor.
  --  Useful when your language has ways of declaring types without an actual implementation.
  map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

  -- Jump to the type of the word under your cursor.
  --  Useful when you're not sure what type a variable is and you want to see
  --  the definition of its *type*, not where it was *defined*.
  map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

  -- Fuzzy find all the symbols in your current document.
  --  Symbols are things like variables, functions, types, etc.
  map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

  -- Fuzzy find all the symbols in your current workspace
  --  Similar to document symbols, except searches over your whole project.
  map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

  -- Rename the variable under your cursor
  --  Most Language Servers support renaming across files, etc.
  map("<leader>cr", vim.lsp.buf.rename, "[C]ode [R]ename")

  -- Execute a code action, usually your cursor needs to be on top of an error
  -- or a suggestion from your LSP for this to activate.
  map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

  -- Opens a popup that displays documentation about the word under your cursor
  --  See `:help K` for why this keymap
  map("K", vim.lsp.buf.hover, "Hover Documentation")

  -- WARN: This is not Goto Definition, this is Goto Declaration.
  --  For example, in C this would take you to the header
  map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
end

function M.setup_cmp_keymaps(cmp)
  return {
    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
    ["<C-d>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }
end

function M.setup_neotree_keymaps()
  map_normal_mode("<leader>e", ":Neotree source=filesystem reveal=true position=left toggle=true<CR>", "N[E]oTree")
  map_normal_mode("<leader>sb", ":Neotree buffers reveal float<CR>", "[S]earch [B]uffers")
end

function M.setup_telescope_keymaps()
  map_normal_mode("<leader><leader>", require("telescope.builtin").find_files, "Find Files")

  -- git
  map_normal_mode("<leader>gc", "<cmd>Telescope git commits<CR>", "[g]it [c]ommits")
  map_normal_mode("<leader>gs", "<cmd>Telescope git status<CR>", "[g]it [s]tatus")

  -- search
  map_normal_mode('<leader>s"', "<cmd>Telescope registers<cr>", '[s]earch ["]registers')
  map_normal_mode("<leader>sa", "<cmd>Telescope autocommands<cr>", "[s]earch [a]utocommands")
  map_normal_mode("<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", "[s]earch [b]uffer")
  map_normal_mode("<leader>sc", "<cmd>Telescope command_history<cr>", "[s]earch [c]ommand history")
  map_normal_mode("<leader>sC", "<cmd>Telescope commands<cr>", "[s]earch [C]ommands")
  map_normal_mode("<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", "[s]earch [d]ocument diagnostics")
  map_normal_mode("<leader>sD", "<cmd>Telescope diagnostics<cr>", "[s]earch [D]iagnostics")
  -- map_normal_mode("<leader>sg", require("telescope.builtin").live_grep, "[s]earch [g]rep")
  map_normal_mode("<leader>sg", require("telescope").extensions.live_grep_args.live_grep_args, "[s]earch [g]rep")
  map_normal_mode("<leader>/", require("telescope").extensions.live_grep_args.live_grep_args, "[s]earch [g]rep")
  map_normal_mode("<leader>sh", "<cmd>Telescope help_tags<cr>", "[s]earch [h]elp pages")
  map_normal_mode("<leader>sH", "<cmd>Telescope highlights<cr>", "[s]earch [H]ighlight groups")
  map_normal_mode("<leader>sk", "<cmd>Telescope keymaps<cr>", "[s]earch [k]ey maps")
  map_normal_mode("<leader>sM", "<cmd>Telescope man_pages<CR>", "[s]earch [M]an pages")
  map_normal_mode("<leader>sm", "<cmd>Telescope marks<cr>", "[s]earch [m]arks")
  map_normal_mode("<leader>so", "<cmd>Telescope vim_options<cr>", "[s]earch [o]ptions")
  map_normal_mode("<leader>sR", "<cmd>Telescope resume<cr>", "[s]earch [R]esume")
end

function M.setup_coderunner_keymaps()
  map_normal_mode("<leader>rf", ":RunFile term<CR>", "[r]unner [f]ile")
end

function M.setup_lazygit_keymaps()
  --   "LazyGit",
  --   "LazyGitConfig",
  --   "LazyGitCurrentFile",
  --   "LazyGitFilter",
  --   "LazyGitFilterCurrentFile",
  map_normal_mode("<leader>gg", ":LazyGit<CR>", "[g]it [g]ui")
end

function M.setup_gitsigns_keymaps(bufnr)
  local gs = package.loaded.gitsigns

  vim.keymap.set("n", "]c", function()
    if vim.wo.diff then
      return "]c"
    end
    vim.schedule(function()
      gs.next_hunk()
    end)
    return "<Ignore>"
  end, { expr = true })

  vim.keymap.set("n", "[c", function()
    if vim.wo.diff then
      return "[c"
    end
    vim.schedule(function()
      gs.prev_hunk()
    end)
    return "<Ignore>"
  end, { expr = true })

  vim.keymap.set({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", { buffer = bufnr, silent = true, noremap = true, desc = "[s]tage hunk" })
  vim.keymap.set({ "n", "v" }, "<leader>hS", ":Gitsigns stage_buffer<CR>", { buffer = bufnr, silent = true, noremap = true, desc = "[S]tage buffer" })
  vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk, { buffer = bufnr, silent = true, noremap = true, desc = "[u]ndo stage hunk" })
  vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { buffer = bufnr, silent = true, noremap = true, desc = "[r]eset hunk" })
  vim.keymap.set("n", "<leader>hR", gs.reset_buffer, { buffer = bufnr, silent = true, noremap = true, desc = "[R]eset buffer" })
  vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { buffer = bufnr, silent = true, noremap = true, desc = "[p]review hunk" })
  vim.keymap.set("n", "<leader>hd", gs.diffthis, { buffer = bufnr, silent = true, noremap = true, desc = "[d]iff this" })

  vim.keymap.set("n", "<leader>hD", function()
    gs.diffthis("~")
  end, { buffer = bufnr, silent = true, noremap = true, desc = "[D]iff this ~" })

  vim.keymap.set("n", "<leader>hb", function()
    gs.blame_line({ full = true })
  end, { buffer = bufnr, silent = true, noremap = true, desc = "[d]iff this" })

  vim.keymap.set("n", "<leader>hB", gs.toggle_current_line_blame, { buffer = bufnr, silent = true, noremap = true, desc = "Toggle line [B]lame" })
end

function M.setup_neogit_keymaps()
  local neogit = require("neogit")
  vim.keymap.set("n", "<leader>gs", neogit.open, { silent = true, noremap = true, desc = "[g]it [s]tatus" })
  vim.keymap.set("n", "<leader>gc", ":Neogit commit<CR>", { silent = true, noremap = true, desc = "[g]it [c]ommit" })
  vim.keymap.set("n", "<leader>gp", ":Neogit pull<CR>", { silent = true, noremap = true, desc = "[g]it [p]ull" })
  vim.keymap.set("n", "<leader>gP", ":Neogit push<CR>", { silent = true, noremap = true, desc = "[g]it [P]ush" })
  vim.keymap.set("n", "<leader>gB", ":Telescope git_branches<CR>", { silent = true, noremap = true, desc = "[g]it [B]ranches" })
end

function M.setup_git_blame_keymaps()
  return {
    -- toggle needs to be called twice; https://github.com/f-person/git-blame.nvim/issues/16
    { "<leader>gbb", ":GitBlameToggle<CR>", desc = "Blame line (toggle)", silent = true },
    { "<leader>gbe", ":GitBlameEnable<CR>", desc = "Blame line (enable)", silent = true },
    { "<leader>gbd", ":GitBlameDisable<CR>", desc = "Blame line (disable)", silent = true },
    { "<leader>gbs", ":GitBlameCopySHA<CR>", desc = "Copy SHA", silent = true },
    { "<leader>gbc", ":GitBlameCopyCommitURL<CR>", desc = "Copy commit URL", silent = true },
    { "<leader>gbf", ":GitBlameCopyFileURL<CR>", desc = "Copy file URL", silent = true },
  }
end

function M.setup_fugitive_keymaps()
  vim.keymap.set("n", "<leader>gbB", ":G blame", { silent = true, noremap = true, desc = "[g]it [B]lame on the side" })
end

function M.setup_neotest_keymaps()
  -- TODO: use these...
  -- { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File" },
  -- { "<leader>tT", function() require("neotest").run.run(vim.loop.cwd()) end, desc = "Run All Test Files" },
  -- { "<leader>tr", function() require("neotest").run.run() end, desc = "Run Nearest" },
  -- { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last" },
  -- { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary" },
  -- { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output" },
  -- { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel" },
  -- { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop" },

  map_normal_mode("<leader>ts", ":Neotest summary<CR>", "[t]est [s]ummary")
  map_normal_mode("<leader>tn", require("neotest").run.run, "[t]est [n]earest")
  map_normal_mode("<leader>to", ":Neotest output<CR>", "[t]est [o]utput")
  map_normal_mode("<leader>tO", ":Neotest output-panel<CR>", "[t]est [O]utput panel")
  map_normal_mode("<leader>tt", require("neotest").run.stop, "[t]est S[t]op nearest")
  map_normal_mode("<leader>ta", require("neotest").run.attach, "[t]est [a]ttach")
  map_normal_mode("<leader>tf", ':lua require("neotest").run.run(vim.fn.expand("%"))<CR>', "[t]est all in [f]ile")
  map_normal_mode("<leader>tS", ":lua require('neotest').run.run({ suite = true })<CR>", "[t]est all in [S]uite")

  map_normal_mode("<leader>td", ':lua require("neotest").run.run({ strategy = "dap" })<CR>', "[t]est [d]ebug Nearest")
  map_normal_mode("<leader>tg", function()
    -- FIXME: https://github.com/nvim-neotest/neotest-go/issues/12
    -- Depends on "leoluz/nvim-dap-go"
    require("dap-go").debug_test()
  end, "[d]ebug [g]o (nearest test)")
end

function M.setup_coverage_keymaps()
  map_normal_mode("<leader>tc", ":Coverage<CR>", "[t]est [c]overage in gutter")
  map_normal_mode("<leader>tC", ":CoverageLoad<CR>:CoverageSummary<CR>", "[t]est [C]overage summary")
end

function M.setup_spectre_keymaps()
  map_normal_mode("<leader>spt", ":lua require('spectre').toggle()<CR>", "[s][p]ectre [t]oggle")
  map_normal_mode("<leader>spw", ":lua require('spectre').open_visual({select_word=true})<CR>", "[s][p]ectre current [w]ord")
  map_normal_mode("<leader>spf", ':lua require("spectre").open_file_search({select_word=true})<CR>', "[s][p]ectre current [f]ile")
end

function M.setup_aerial_keymaps()
  map_normal_mode("<leader>cs", ":AerialToggle<CR>", "[s]ymbols")
end

function M.setup_dap_ui_keymaps()
  map_normal_mode("<leader>du", function()
    require("dapui").toggle({})
  end, "[d]ap [u]i")

  vim.keymap.set({ "n", "v" }, "<leader>de", function()
    require("dapui").eval()
  end, { desc = "[d]ap [e]val" })
end

function M.setup_dap_keymaps()
  map_normal_mode("<leader>dB", function()
    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
  end, "[d]ebug [B]reakpoint")

  map_normal_mode("<leader>db", function()
    require("dap").toggle_breakpoint()
  end, "toggle [d]ebug [b]reakpoint")

  map_normal_mode("<leader>dc", function()
    require("dap").continue()
  end, "[d]ebug [c]ontinue")

  map_normal_mode("<leader>dC", function()
    require("dap").run_to_cursor()
  end, "[d]ebug [C]ursor")

  map_normal_mode("<leader>da", function()
    ---@param config {args?:string[]|fun():string[]?}
    local function get_args(config)
      local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
      config = vim.deepcopy(config)
      ---@cast args string[]
      config.args = function()
        local new_args = vim.fn.input("Run with args: ", table.concat(args, " ")) --[[@as string]]
        return vim.split(vim.fn.expand(new_args) --[[@as string]], " ")
      end
      return config
    end

    require("dap").continue({ before = get_args })
  end, "[d]ebug [a]rgs")

  map_normal_mode("<leader>dg", function()
    require("dap").goto_()
  end, "[d]ebug [g]o to line")

  map_normal_mode("<leader>di", function()
    require("dap").step_into()
  end, "[d]ebug [i]nto")

  map_normal_mode("<leader>dj", function()
    require("dap").down()
  end, "[d]ebug [j]ump down")

  map_normal_mode("<leader>dk", function()
    require("dap").up()
  end, "[d]ebug [k]ump up")

  map_normal_mode("<leader>dl", function()
    require("dap").run_last()
  end, "[d]ebug [l]ast")

  map_normal_mode("<leader>do", function()
    require("dap").step_out()
  end, "[d]ebug [o]ut")

  map_normal_mode("<leader>dO", function()
    require("dap").step_over()
  end, "[d]ebug [O]ver")

  map_normal_mode("<leader>dp", function()
    require("dap").pause()
  end, "[d]ebug [p]ause")

  map_normal_mode("<leader>dr", function()
    require("dap").repl.toggle()
  end, "[d]ebug [r]epl")

  map_normal_mode("<leader>ds", function()
    require("dap").session()
  end, "[d]ebug [s]ession")

  map_normal_mode("<leader>dt", function()
    require("dap").terminate()
  end, "[d]ebug [t]erminate")

  map_normal_mode("<leader>dw", function()
    require("dap.ui.widgets").hover()
  end, "[d]ebug [w]idgets")
end

function M.setup_noice_keymaps()
  map_normal_mode("<leader>sna", ":Noice<CR>", "[s]earch [n]oice [a]ll")
  map_normal_mode("<leader>snl", ":NoiceLast<CR>", "[s]earch [n]oice [l]ast")
  map_normal_mode("<leader>snd", ":NoiceDismiss<CR>", "[s]earch [n]oice [d]ismiss")
  map_normal_mode("<leader>snL", ":NoiceLog<CR>", "[s]earch [n]oice [L]og")
end

function M.setup_terminal_keymaps()
  -- Both <C-/> and <C-_> are mapped due to the way control characters are interpreted by terminal emulators.
  -- ASCII value of '/' is 47, and of '_' is 95. When <C-/> is pressed, the terminal sends (47 - 64) which wraps around to 111 ('o').
  -- When <C-_> is pressed, the terminal sends (95 - 64) which is 31. Hence, both key combinations need to be mapped.

  -- <C-/> toggles the floating terminal
  local floating_term_cmd = "<cmd>lua require('utils.terminal').toggle_fterm()<CR>"
  local split_term_cmd = "<cmd>lua require('utils.terminal').toggle_terminal_native()<CR>"
  vim.keymap.set({ "n", "i", "t", "v" }, "<C-/>", split_term_cmd, { desc = "Toggle terminal" })
  vim.keymap.set({ "n", "i", "t", "v" }, "<C-_>", split_term_cmd, { desc = "Toggle terminal" })

  -- C-A-/ toggles split terminal on/off
  vim.keymap.set({ "n", "i", "t", "v" }, "<C-A-/>", floating_term_cmd, { desc = "Toggle native terminal" })
  vim.keymap.set({ "n", "i", "t", "v" }, "<C-A-_>", floating_term_cmd, { desc = "Toggle native terminal" })

  -- Esc goes to NORMAL mode from TERMINAL mode
  vim.api.nvim_set_keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { noremap = true })
end

function M.setup_conform_keymaps()
  map_normal_mode("<leader>uf", require("utils.formatting").toggle_formatting, "Toggle auto-formatting")
end

function M.setup_winshift_keymaps()
  vim.keymap.set({ "n", "v" }, "<leader>uw", "<cmd>WinShift<CR>", { desc = "[w]inshift (shift + arrows)" })
end

function M.setup_obsidian_keymaps()
  return {
    { "<leader>ns", "<cmd>ObsidianSearch<cr>", desc = "[N]otes: [s]earch text" },
    { "<leader>nf", "<cmd>ObsidianQuickSwitch<cr>", desc = "[N]otes: search [f]ilenames" },
    { "<leader>nn", "<cmd>ObsidianNew<cr>", desc = "[N]otes: [n]new" },
    { "<leader>nl", "<cmd>ObsidianQuickSwitch LEARNING<cr><cr>", desc = "[N]otes: [l]earning" },
    { "<leader>no", "<cmd>ObsidianOpen<cr>", desc = "[N]otes: [O]pen Obsidian" },
  }
end

function M.setup_whichkey()
  return {
    ["<leader>c"] = {
      name = "+code",
    },
    ["<leader>d"] = {
      name = "+debug",
    },
    ["<leader>f"] = {
      name = "+file",
    },
    ["<leader>g"] = {
      name = "+git",
    },
    ["<leader>gb"] = {
      name = "+blame",
    },
    ["<leader>gd"] = {
      name = "+diffview",
    },
    ["<leader>h"] = {
      name = "+hunks",
    },
    ["<leader>n"] = {
      name = "+notes",
    },
    ["<leader>s"] = {
      name = "+search",
    },
    ["<leader>sn"] = {
      name = "+noice",
    },
    ["<leader>sp"] = {
      name = "+spectre",
    },
    ["<leader>t"] = {
      name = "+test",
    },
    ["<leader>u"] = {
      name = "+ui",
    },
    ["<leader>r"] = {
      name = "+run",
    },
    ["<leader>x"] = {
      name = "+diagnostics/quickfix",
    },
  }
end

function M.setup_rest_keymaps()
  map_normal_mode("<leader>rr", "<Plug>RestNvim", "Run REST request under cursor")
end

function M.setup_yanky_keymaps()
  map_normal_mode("<leader>p", function()
    require("telescope").extensions.yank_history.yank_history({})
  end, "Yanky history")
end

return M
