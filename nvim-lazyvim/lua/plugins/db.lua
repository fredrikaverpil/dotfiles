return {

  {
    "tpope/vim-dadbod",
    dependencies = {
      { "kristijanhusak/vim-dadbod-ui" },
      { "kristijanhusak/vim-dadbod-completion" },
      { "hrsh7th/nvim-cmp" }, -- see cmp.lua
    },
    config = function()
      local cmp = require("cmp")

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          cmp.setup.buffer({ sources = { { name = "vim-dadbod-completion" } } })
        end,
      })

      vim.g.db_ui_save_location = "~/.local/share/db_ui"
    end,
  },
}
