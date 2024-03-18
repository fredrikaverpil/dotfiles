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

      local autocomplete_group = vim.api.nvim_create_augroup("vimrc_autocompletion", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = sql_ft,
        callback = function()
          local cmp = require("cmp")
          local global_sources = cmp.get_config().sources
          local buffer_sources = {}

          -- add globally defined sources (see separate nvim-cmp config)
          -- this makes e.g. luasnip snippets available since luasnip is configured globally
          if global_sources then
            for _, source in ipairs(global_sources) do
              table.insert(buffer_sources, { name = source.name })
            end
          end

          -- add vim-dadbod-completion source
          table.insert(buffer_sources, { name = "vim-dadbod-completion" })

          -- update sources for the current buffer
          cmp.setup.buffer({ sources = buffer_sources })
        end,
        group = autocomplete_group,
      })
    end,
  },
}
