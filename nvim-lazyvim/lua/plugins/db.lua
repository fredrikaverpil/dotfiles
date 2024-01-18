return {

  {
    "tpope/vim-dadbod",
    dependencies = {
      { "kristijanhusak/vim-dadbod-ui" },
      { "kristijanhusak/vim-dadbod-completion" },
    },
    config = function()
      vim.g.db_ui_save_location = "~/.local/share/db_ui"

      -- also see nvim-cmp config for vim-dadbod-completion setup
    end,
  },
}
