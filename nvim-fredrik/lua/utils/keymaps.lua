M = {}

local map_normal_mode = function(keys, func, desc)
  vim.keymap.set("n", keys, func, { desc = desc })
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
  -- map_normal_mode("<leader>sg", require("telescope.builtin").live_grep, "[s]earch [g]rep")
  map_normal_mode("<leader>sg", require("telescope").extensions.live_grep_args.live_grep_args, "[s]earch [g]rep")
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

return M
