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

      local autocomplete_group = vim.api.nvim_create_augroup("vimrc_autocompletion", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = sql_ft,
        callback = function()
          local cmp = require("cmp")
          local sources = cmp.get_config().sources
          local updated_sources = {}

          -- add globally defined sources (see separate nvim-cmp config)
          -- this makes e.g. luasnip snippets available since luasnip is configured globally
          for _, source in ipairs(sources) do
            table.insert(updated_sources, { name = source.name })
          end

          -- add vim-dadbod-completion source
          table.insert(updated_sources, { name = "vim-dadbod-completion" })

          -- update sources for the current buffer
          cmp.setup.buffer({
            sources = updated_sources,
          })
        end,
        group = autocomplete_group,
      })
    end,
  },
}
