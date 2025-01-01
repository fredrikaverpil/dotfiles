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
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    opts = function(_, opts)
      vim.opt.sessionoptions = "buffers,curdir,help,tabpages,winsize,winpos,terminal,localoptions"
      return opts
    end,
    keys = require("fredrik.config.keymaps").setup_auto_session_keymaps(),
  },
}
