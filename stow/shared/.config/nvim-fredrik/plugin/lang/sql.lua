require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/jsborjesson/vim-uppercase-sql" },
    { src = "https://github.com/tpope/vim-dadbod" },
    { src = "https://github.com/kristijanhusak/vim-dadbod-ui" },
    { src = "https://github.com/kristijanhusak/vim-dadbod-completion" },
    { src = "https://github.com/Maxteabag/sqlit.nvim" },
  })

  vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("sql-build", { clear = true }),
    callback = function(ev)
      if ev.data.spec.name == "sqlit.nvim" then
        vim.system({ "uv", "tool", "install", "sqlit-tui", "--with", "google-cloud-bigquery" })
      end
    end,
  })

  vim.g.db_ui_save_location = "~/code/dbui"
  vim.g.db_ui_tmp_query_location = "~/code/queries"
  vim.g.db_ui_use_nerd_fonts = true
  vim.g.db_ui_execute_on_save = false
  vim.g.db_ui_use_nvim_notify = true

  local sqlit_ready = false
  vim.keymap.set("n", "<leader>D", function()
    if not sqlit_ready then
      sqlit_ready = true
      require("sqlit").setup({})
    end
    require("sqlit").open()
  end, { desc = "Database (sqlit)" })
end)
