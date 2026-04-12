require("lazyload").on_vim_enter(function()
  -- native diagnostics
  do
    local icons = require("icons").diagnostics

    vim.diagnostic.config({
      enable = true,

      virtual_lines = false,
      -- virtual_lines = {
      --   -- Only show virtual line diagnostics for the current cursor line
      --   current_line = false,
      -- },

      -- NOTE: disabled due to using the tiny-inline-diagnostic.nvim plugin
      virtual_text = false,
      -- virtual_text = function(_, _)
      --   ---@class vim.diagnostic.Opts.VirtualText
      --   return { spacing = 4, source = "if_many", prefix = prefix }
      -- end,

      underline = true,
      update_in_insert = false,
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = icons.Error,
          [vim.diagnostic.severity.WARN] = icons.Warn,
          [vim.diagnostic.severity.HINT] = icons.Hint,
          [vim.diagnostic.severity.INFO] = icons.Info,
        },
      },
    })
  end

  -- tiny-inline-diagnostic
  do
    vim.pack.add({
      { src = "https://github.com/rachartier/tiny-inline-diagnostic.nvim" },
    })

    require("tiny-inline-diagnostic").setup({
      options = {
        show_all_diags_on_cursorline = true,
        multilines = {
          enabled = true,
          always_show = true,
        },
        show_source = {
          enabled = true,
        },
      },
    })
  end
end)
