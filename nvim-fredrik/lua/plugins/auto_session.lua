local function deactivate_python_venv()
  vim.env.VIRTUAL_ENV = nil
  require("venv-selector").deactivate()
end

local function activate_python_venv()
  if vim.env.VIRTUAL_ENV ~= nil then
    require("venv-selector").activate_from_path(vim.env.VIRTUAL_ENV)
  elseif vim.fn.isdirectory(".venv") == 1 then
    local venv_path = vim.fn.getcwd() .. "/.venv"
    vim.env.VIRTUAL_ENV = venv_path
    require("venv-selector").activate_from_path(venv_path)
  end
end

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

return {
  {
    "rmagatti/auto-session",
    lazy = false,
    dependencies = {
      "linux-cultist/venv-selector.nvim",
      "nvim-telescope/telescope.nvim",
    },
    opts = function(_, opts)
      ---@type AutoSession.Config
      opts = opts or {}

      -- opts.log_level = "debug"

      opts.pre_save_cmds = {
        delete_hidden_buffers,
      }

      opts.pre_restore_cmds = {
        deactivate_python_venv,
      }

      opts.post_restore_cmds = {
        require("utils.private").toggle_copilot,
        activate_python_venv,
        require("lualine").refresh,
      }

      opts.session_lens = {
        load_on_setup = true,
        previewer = false,
      }
    end,
    config = function(_, opts)
      -- vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
      vim.opt.sessionoptions = "buffers,curdir,help,tabpages,winsize,winpos,terminal"
      require("auto-session").setup(opts)
    end,
    keys = require("config.keymaps").setup_auto_session_keymaps(),
  },
}
