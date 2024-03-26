return {
  {
    "folke/noice.nvim",
    priority = 800,
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

          opts.dap = {
            lualine_component = {
              mode,
              cond = function()
                return package.loaded["noice"] and require("noice").api.status.mode.has()
              end,
              color = require("utils.colors").fgcolor("Constant"),
            },
          }
        end,
      },
    },
    config = function()
      require("noice").setup({
        lsp = {
          -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
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

      require("config.keymaps").setup_noice_keymaps()
    end,
  },
}
