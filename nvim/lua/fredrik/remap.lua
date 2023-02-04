--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Inspirations
-- https://www.chiarulli.me/Neovim-2/02-keymaps/

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --

-- Netrw
-- vim.keymap.set("n", "<leader>ex", vim.cmd.Ex)

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- Resize with arrows
vim.keymap.set("n", "<A-Up>", ":resize -2<CR>", opts)
vim.keymap.set("n", "<A-Down>", ":resize +2<CR>", opts)
-- vim.keymap.set("n", "<A-Left>", ":vertical resize -2<CR>", opts)
-- vim.keymap.set("n", "<A-Right>", ":vertical resize +2<CR>", opts)

