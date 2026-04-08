-- SQL: vim-dadbod, vim-dadbod-ui, sqlit.

vim.pack.add({
  { src = "https://github.com/jsborjesson/vim-uppercase-sql" },
  { src = "https://github.com/tpope/vim-dadbod" },
  { src = "https://github.com/kristijanhusak/vim-dadbod-ui" },
  -- vim-dadbod-completion is installed in plugin/core/blink.lua
})

vim.g.db_ui_save_location = "~/code/dbui"
vim.g.db_ui_tmp_query_location = "~/code/queries"
vim.g.db_ui_use_nerd_fonts = true
vim.g.db_ui_execute_on_save = false
vim.g.db_ui_use_nvim_notify = true

-- sqlit.nvim
vim.pack.add({
  { src = "https://github.com/Maxteabag/sqlit.nvim" },
})

require("sqlit").setup({})

vim.keymap.set("n", "<leader>D", function()
  require("sqlit").open()
end, { desc = "Database (sqlit)" })
