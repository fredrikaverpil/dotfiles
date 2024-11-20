local sql_ft = { "sql", "mysql", "plsql" }

return {

  { "jsborjesson/vim-uppercase-sql", ft = sql_ft },

  {
    "tpope/vim-dadbod",
    enabled = true,
    dependencies = {
      { "kristijanhusak/vim-dadbod-ui" },
      { "kristijanhusak/vim-dadbod-completion" },
    },
    cmd = { "DBUI", "DBUIFindBuffer" },
    config = function()
      vim.g.db_ui_save_location = "~/code/dbui"
      vim.g.db_ui_tmp_query_location = "~/code/queries"
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_execute_on_save = false
      vim.g.db_ui_use_nvim_notify = true
    end,
  },

  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        completion = {
          enabled_providers = { "dadbod" },
        },
        providers = {
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        },
      },
    },
    dependencies = {
      "kristijanhusak/vim-dadbod-completion",
    },
  },
}
