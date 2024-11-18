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

return {
  {
    "rmagatti/auto-session",

    dependencies = {
      "linux-cultist/venv-selector.nvim",
    },

    lazy = false,

    opts = function(_, opts)
      ---@type AutoSession.Config
      opts = opts or {}

      -- opts.log_level = "debug"

      opts.pre_restore_cmds = {
        deactivate_python_venv,
      }

      opts.post_restore_cmds = {
        require("utils.private").toggle_copilot,
        activate_python_venv,
        require("lualine").refresh,
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
