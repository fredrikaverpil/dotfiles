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
      vim.g.db_ui_save_location = "~/code/dbui"
      vim.g.db_ui_tmp_query_location = "~/code/queries"
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_execute_on_save = false
      vim.g.db_ui_use_nvim_notify = true

      local cmp = require("cmp")
      local sources = cmp.get_config().sources
      local updated_sources = table.insert(sources, { name = "vim-dadbod-completion", group_index = 1, option = {} })

      cmp.setup.buffer({
        sources = updated_sources,
      })

      print(vim.inspect(cmp.get_config().sources))
    end,
  },
}
