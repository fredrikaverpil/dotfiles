local function delete_hidden_buffers()
  local visible = {}
  for _, win in pairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(win)] = true
  end
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if not visible[buf] then
      vim.api.nvim_buf_delete(buf, {})
    end
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceLoadPost",
  callback = function(session)
    require("fredrik.utils.private").toggle_copilot()
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceSavePre",
  callback = function(session)
    delete_hidden_buffers()
  end,
})

return {
  {
    "folke/persistence.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    event = "VimEnter",
    init = function()
      -- https://neovim.io/doc/user/options.html#'sessionoptions'
      vim.opt.sessionoptions = { "buffers", "curdir", "folds", "help", "localoptions", "winpos", "winsize" }
    end,
    config = function(_, opts)
      require("persistence").setup(opts)

      -- Auto-load the last session when starting Neovim
      -- vim.schedule(function()
      --   require("persistence").load()
      -- end)
    end,
    -- NOTE: snacks zoxide picker is used to select sessions
  },
}
