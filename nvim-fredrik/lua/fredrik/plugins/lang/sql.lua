local sql_ft = { "sql", "mysql", "plsql" }

return {

  {
    "jsborjesson/vim-uppercase-sql",
    lazy = true,
    ft = sql_ft,
  },

  {
    "tpope/vim-dadbod",
    lazy = true,
    enabled = true,
    dependencies = {
      { "kristijanhusak/vim-dadbod-ui" },
      { "kristijanhusak/vim-dadbod-completion" },
    },
    config = function()
      vim.g.db_ui_save_location = "~/code/dbui"
      vim.g.db_ui_tmp_query_location = "~/code/queries"
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_execute_on_save = false
      vim.g.db_ui_use_nvim_notify = true
    end,
    cmd = { "DBUI", "DBUIFindBuffer" },
  },

  {
    "saghen/blink.cmp",
    dependencies = {
      "kristijanhusak/vim-dadbod-completion",
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      sources = {
        default = { "dadbod" },
        providers = {
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        },
      },
    },
    opts_extend = {
      "sources.default",
    },
  },
}
