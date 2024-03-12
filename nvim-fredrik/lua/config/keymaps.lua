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

local map_normal_mode = function(keys, func, desc)
  -- default values:
  -- noremap: false
  -- silent: false
  vim.keymap.set("n", keys, func, { desc = desc, noremap = false, silent = false })
end

M.setup_lsp_keymaps = function()
  -- Jump to the definition of the word under your cursor.
  --  This is where a variable was first declared, or where a function is defined, etc.
  --  To jump back, press <C-T>.
  map_normal_mode("gd", require("telescope.builtin").lsp_definitions, "[g]oto [d]efinition")

  map_normal_mode("gD", vim.lsp.buf.declaration, "[g]oto [D]eclaration")

  -- Find references for the word under your cursor.
  map_normal_mode("gr", require("telescope.builtin").lsp_references, "[g]oto [r]eferences")

  -- Jump to the implementation of the word under your cursor.
  --  Useful when your language has ways of declaring types without an actual implementation.
  map_normal_mode("gI", require("telescope.builtin").lsp_implementations, "[g]oto [I]mplementation")

  -- Jump to the type of the word under your cursor.
  --  Useful when you're not sure what type a variable is and you want to see
  --  the definition of its *type*, not where it was *defined*.
  map_normal_mode("<leader>D", require("telescope.builtin").lsp_type_definitions, "Goto Type [D]efinition")

  -- Fuzzy find all the symbols in your current document.
  --  Symbols are things like variables, functions, types, etc.
  map_normal_mode("<leader>ss", require("telescope.builtin").lsp_document_symbols, "[s]ymbols in Document")

  -- Fuzzy find all the symbols in your current workspace
  --  Similar to document symbols, except searches over your whole project.
  map_normal_mode("<leader>sS", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[S]ymbols in Workspace")

  -- Rename the variable under your cursor
  --  Most Language Servers support renaming across files, etc.
  map_normal_mode("<leader>cr", vim.lsp.buf.rename, "[C]ode [R]ename")

  -- Execute a code action, usually your cursor needs to be on top of an error
  -- or a suggestion from your LSP for this to activate.
  map_normal_mode("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

  -- Opens a popup that displays documentation about the word under your cursor
  --  See `:help K` for why this keymap
  map_normal_mode("K", vim.lsp.buf.hover, "Hover Documentation")
end

M.setup_cmp_keymaps = function(cmp)
  return {
    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
    ["<C-d>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }
end

M.setup_neotree_keymaps = function()
  map_normal_mode("<leader>e", ":Neotree source=filesystem reveal=true position=left toggle=true<CR>", "N[E]oTree")
  map_normal_mode("<leader>sb", ":Neotree buffers reveal float<CR>", "[S]earch [B]uffers")
end

M.setup_telescope_keymaps = function()
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

M.setup_coderunner_keymaps = function()
  map_normal_mode("<leader>rf", ":RunFile term<CR>", "[r]unner [f]ile")
end

M.setup_lazygit_keymaps = function()
  --   "LazyGit",
  --   "LazyGitConfig",
  --   "LazyGitCurrentFile",
  --   "LazyGitFilter",
  --   "LazyGitFilterCurrentFile",
  map_normal_mode("<leader>gg", ":LazyGit<CR>", "[g]it [g]ui")
end

M.setup_gitsigns_keymaps = function()
  map_normal_mode("<leader>gp", ":Gitsigns preview_hunk<CR>", "[g]it [p]review hunk")
  map_normal_mode("<leader>gr", ":Gitsigns reset_hunk<CR>", "[g]it [r]eset hunk")
  map_normal_mode("<leader>gR", ":Gitsigns reset_buffer<CR>", "[g]it [R]eset buffer")
  map_normal_mode("<leader>gs", ":Gitsigns stage_hunk<CR>", "[g]it [s]tage hunk")
  map_normal_mode("<leader>gu", ":Gitsigns undo_stage_hunk<CR>", "[g]it [u]ndo stage hunk")
  map_normal_mode("<leader>gB", ":Gitsigns toggle_current_line_blame<CR>", "[g]it [b]lame toggle")
  map_normal_mode("<leader>gB", ":Gitsigns blame_line<CR>", "[g]it [B]lame line")
end

M.setup_neotest_keymaps = function()
  map_normal_mode("<leader>ts", ":Neotest summary<CR>", "[t]est [s]ummary")
  map_normal_mode("<leader>tn", require("neotest").run.run, "[t]est [n]earest")
  map_normal_mode("<leader>to", ":Neotest output", "[t]est [o]utput")
  map_normal_mode("<leader>tO", ":Neotest output-panel", "[t]est [O]utput panel")
  map_normal_mode("<leader>tt", require("neotest").run.stop, "[t]est S[t]op nearest")
  map_normal_mode("<leader>ta", require("neotest").run.attach, "[t]est [a]ttach")
  map_normal_mode("<leader>tf", ':lua require("neotest").run.run(vim.fn.expand("%"))<CR>', "[t]est all in [f]ile")
  map_normal_mode("<leader>tS", ":lua require('neotest').run.run({ suite = true })<CR>", "[t]est all in [S]uite")
  map_normal_mode("<leader>tS", ':lua require("neotest").run.run({ strategy = "dap" })<CR>', "[t]est [d]ebug Nearest")
end

M.setup_coverage_keymaps = function()
  map_normal_mode("<leader>tc", ":Coverage<CR>", "[t]est [c]overage in gutter")
  map_normal_mode("<leader>tC", ":CoverageLoad<CR>:CoverageSummary<CR>", "[t]est [C]overage summary")
end

M.setup_spectre_keymaps = function()
  map_normal_mode("<leader>spt", ":lua require('spectre').toggle()<CR>", "[s][p]ectre [t]oggle")
  map_normal_mode("<leader>spw", ":lua require('spectre').open_visual({select_word=true})<CR>", "[s][p]ectre current [w]ord")
  map_normal_mode("<leader>spf", ':lua require("spectre").open_file_search({select_word=true})<CR>', "[s][p]ectre current [f]ile")
end

M.setup_aerial_keymaps = function()
  map_normal_mode("<leader>ss", ":AerialToggle<CR>", "[s]ymbols")
end

M.setup_dap_keymaps = function()
  map_normal_mode("<leader>db", ":DapToggleBreakpoint<CR>", "[d]ebug [b]reakpoint")
  map_normal_mode("<leader>dc", ":DapContinue<CR>", "[d]ebug [c]ontinue")
  map_normal_mode("<leader>dx", ":DapTerminate<CR>", "[d]ebug e[x]it")
  map_normal_mode("<leader>do", ":DapStepOver<CR>", "[d]ebug step [o]ver")
end

M.setup_noice_keymaps = function()
  map_normal_mode("<leader>sna", ":Noice<CR>", "[s]earch [n]oice [a]ll")
  map_normal_mode("<leader>snl", ":NoiceLast<CR>", "[s]earch [n]oice [l]ast")
  map_normal_mode("<leader>snd", ":NoiceDismiss<CR>", "[s]earch [n]oice [d]ismiss")
  map_normal_mode("<leader>snL", ":NoiceLog<CR>", "[s]earch [n]oice [L]og")
end

M.setup_toggleterm_keymaps = function()
  -- Both <C-/> and <C-_> are mapped due to the way control characters are interpreted by terminal emulators.
  -- ASCII value of '/' is 47, and of '_' is 95. When <C-/> is pressed, the terminal sends (47 - 64) which wraps around to 111 ('o').
  -- When <C-_> is pressed, the terminal sends (95 - 64) which is 31. Hence, both key combinations need to be mapped.

  -- <C-/> toggles the terminal
  vim.keymap.set({ "n", "i", "t", "v" }, "<C-/>", "<cmd>lua require('utils.terminal').toggle_terminal()<CR>", { desc = "Toggle terminal" })
  vim.keymap.set({ "n", "i", "t", "v" }, "<C-_>", "<cmd>lua require('utils.terminal').toggle_terminal()<CR>", { desc = "Toggle terminal" })
  -- Esc goes to NORMAL mode from TERMINAL mode
  vim.api.nvim_set_keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { noremap = true })
end

M.setup_conform_keymaps = function()
  map_normal_mode("<leader>uf", require("utils.formatting").toggle_formatting, "Toggle auto-formatting")
end

M.setup_whichkey = function()
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
    ["<leader>gd"] = {
      name = "+diffview",
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

M.setup_rest_keymaps = function()
  map_normal_mode("<leader>rr", "<Plug>RestNvim", "Run REST request under cursor")
end

return M
