-- options
vim.opt.number = true
vim.opt.wrap = false
vim.opt.signcolumn = "yes"
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = false
vim.opt.colorcolumn = "80"
vim.opt.smartindent = true
vim.opt.swapfile = false
vim.opt.winborder = "rounded"
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.g.mapleader = " "

-- misc. keymaps
local map = vim.keymap.set
map("n", "<leader>o", ":update<CR>:source<CR>", { desc = "Save & source" })
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
map("n", "<leader>`", "<C-^>", { noremap = true, desc = "Alternate buffers" })
map({ "n", "v", "x" }, "<leader>y", '"+y<CR>', { desc = "Yank to system clipboard" })
map({ "n", "v", "x" }, "<leader>d", '"+d<CR>', { desc = "Delete to system clipboard" })

-- plugins
vim.pack.add({
  { src = "https://github.com/echasnovski/mini.pick" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
})
require("mason").setup({ PATH = "append" })
require("mini.pick").setup()
map("n", "<leader><leader>", ":Pick files<CR>")
map("n", "<leader>/", ":Pick grep_live<CR>")
map("n", "<leader>sh", ":Pick help<CR>")
require("nvim-treesitter.configs").setup({
  auto_install = true, -- requires tree-sitter CLI
  ensure_installed = { "lua", "vim", "vimdoc", "markdown", "markdown_inline" },
  highlight = { enable = true },
})

-- lsp
vim.lsp.enable({ "lua_ls", "gopls" })
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true), -- add vim to lua_ls runtime path (recognizes `vim` global)
      },
    },
  },
})

-- auto-completion (:help omnicompletion); trigger manually with CTRL+X CTRL+O
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client then
      if client:supports_method("textDocument/completion") then
        vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
      end
    end
  end,
})
vim.cmd("set completeopt+=noselect") -- do not pre-select the first item
