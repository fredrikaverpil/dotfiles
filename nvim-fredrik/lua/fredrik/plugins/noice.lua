return {
  {
    "folke/noice.nvim",
    lazy = true,
    event = "VeryLazy",
    -- priority = 800,
    opts = {
      -- add any options here
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      {
        "rcarriga/nvim-notify",
        opts = {
          stages = "static", -- no animation
          timeout = 1000, -- 1s
        },
      },
      {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
          local function mode()
            local mode_ = require("noice").api.status.mode.get()
            local filters = { "INSERT", "VISUAL", "TERMINAL" }
            for _, filter in ipairs(filters) do
              if string.find(mode_, filter) then
                return "" -- do not show this mode
              end
            end
            return mode_
          end

          opts.noice = {
            lualine_component = {
              mode,
              cond = function()
                return package.loaded["noice"] and require("noice").api.status.mode.has()
              end,
              color = require("fredrik.utils.colors").fgcolor("Constant"),
            },
          }
        end,
      },
    },
    config = function()
      require("noice").setup({
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
          },
        },
        -- you can enable a preset for easier configuration
        presets = {
          bottom_search = true, -- use a classic bottom cmdline for search
          command_palette = true, -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = false, -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = false, -- add a border to hover docs and signature help
        },
      })

      require("fredrik.config.keymaps").setup_noice_keymaps()
    end,
  },
}
