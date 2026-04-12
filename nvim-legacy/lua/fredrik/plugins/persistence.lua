local function delete_hidden_buffers()
  local visible = {}
  for _, win in pairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(win)] = true
  end
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    if not visible[buf] and vim.api.nvim_buf_is_valid(buf) then
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
      -- Skip special buffers (nofile, terminal, prompt, etc.)
      if buftype == "" then
        pcall(vim.api.nvim_buf_delete, buf, {})
      end
    end
  end
end

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
