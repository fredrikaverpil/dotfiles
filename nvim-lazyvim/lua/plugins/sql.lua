local sql_ft = { "sql", "mysql", "plsql" }

return {

  { "jsborjesson/vim-uppercase-sql", ft = sql_ft },

  {
    "tpope/vim-dadbod",
    enabled = true,
    dependencies = {
      { "kristijanhusak/vim-dadbod-ui" },
      { "kristijanhusak/vim-dadbod-completion", lazy = true, ft = sql_ft },
      {
        "folke/edgy.nvim",
        optional = true,
        opts = function(_, opts)
          table.insert(opts.left, {
            title = "Database",
            ft = "dbui",
            pinned = true,
            open = function()
              vim.cmd("DBUI")
            end,
          })

          table.insert(opts.bottom, {
            title = "DB Query Result",
            ft = "dbout",
          })
        end,
      },
    },
    cmd = { "DBUI", "DBUIFindBuffer" },
    config = function()
      vim.g.db_ui_save_location = "~/.local/share/db_ui"
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_execute_on_save = false
      vim.g.db_ui_use_nvim_notify = true

      local autocomplete_group = vim.api.nvim_create_augroup("vimrc_autocompletion", { clear = true })
      local cmp = require("cmp")
      vim.api.nvim_create_autocmd("FileType", {
        pattern = sql_ft,
        callback = function()
          cmp.setup.buffer({
            sources = {
              { name = "vim-dadbod-completion" },
              { name = "nvim_lsp" },
              { name = "buffer" },
              { name = "luasnip" },
            },
          })
        end,
        group = autocomplete_group,
      })
    end,
  },
}
